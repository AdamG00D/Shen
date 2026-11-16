package com.adam.shen.core

import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayInputStream

/**
 * النسخة الاحتياطية: JSON (شوف `docs/BACKUP_FORMAT.md`) متشفّر كرسالة OpenPGP بكلمة سر
 * (RFC 9580: Argon2 + AES-256-OCB). يعني تقدر تفكها من غير شِن خالص: `sq decrypt backup.shen`.
 *
 * المفاتيح السرية جواها لسه متشفّرة بكلمات سرها، فالنسخة محمية بطبقتين.
 */
class Backup(private val api: Api) {
    private val pgp get() = api.pgp
    private val store get() = api.store

    fun export(profileId: String?, password: String, out: String): Map<String, Any?> {
        if (password.length < Vault.MIN_PASSWORD) throw CoreError(Err.INVALID)
        val chosen = if (profileId != null) listOf(store.profile(profileId)) else store.profiles()
        val skipped = chosen.filter { !store.isOpen(it.id) }.map { it.name }
        if (profileId != null && skipped.isNotEmpty()) throw CoreError(Err.PROFILE_LOCKED)
        var keys = 0
        var contacts = 0
        val profiles = JSONArray()
        for (p in chosen.filter { store.isOpen(it.id) }) {
            val d = store.data(p.id)
            keys += d.keys.size
            contacts += d.contacts.size
            profiles.put(
                JSONObject()
                    .put("name", p.name)
                    .put("color", p.color)
                    .put("default", d.defaultKey ?: JSONObject.NULL)
                    .put("keys", JSONArray(d.keys.map { e -> keyJson(e) }))
                    .put("contacts", JSONArray(d.contacts.map { e -> contactJson(e) })),
            )
        }
        val bundle = JSONObject()
            .put("format", FORMAT)
            .put("version", VERSION)
            .put("created", api.nowMs())
            .put("scope", if (profileId == null) "all" else "profile")
            .put("profiles", profiles)
        if (profileId == null) {
            bundle.put("shared", JSONArray(store.shared().map { contactJson(it) }))
            contacts += store.shared().size
        }
        val bytes = bundle.toString().toByteArray(Charsets.UTF_8)
        var ok = false
        try {
            api.createStream(out).use { o ->
                pgp.encryptWithPassword(ByteArrayInputStream(bytes), o, password, armor = false, modern = true)
            }
            ok = true
        } finally {
            bytes.fill(0)
            if (!ok) runCatching { api.deleteStream(out) }
        }
        return mapOf("profiles" to profiles.length(), "keys" to keys, "contacts" to contacts, "skipped" to skipped)
    }

    fun preview(input: String, password: String): Map<String, Any?> {
        val b = read(input, password)
        val profiles = b.optJSONArray("profiles").objects().map { p ->
            mapOf(
                "name" to p.optString("name"),
                "keys" to (p.optJSONArray("keys")?.length() ?: 0),
                "contacts" to (p.optJSONArray("contacts")?.length() ?: 0),
                "exists" to store.profiles().any { it.name == p.optString("name") },
            )
        }
        return mapOf(
            "created" to b.optLong("created"),
            "scope" to b.optString("scope"),
            "profiles" to profiles,
            "shared" to (b.optJSONArray("shared")?.length() ?: 0),
        )
    }

    /**
     * بيدمج: كل بروفايل في النسخة بيروح للبروفايل اللي بنفس الاسم (أو بروفايل جديد).
     * مفيش حاجة بتتمسح، والمفاتيح الموجودة بتتحدّث بس.
     */
    fun import(input: String, password: String): Map<String, Any?> {
        val b = read(input, password)
        var added = 0
        var updated = 0
        var createdProfiles = 0
        val list = b.optJSONArray("profiles").objects()
        // نتأكد الأول إن مفيش بروفايل بنفس الاسم مقفول (عشان منعملش نسخة مكررة منه)
        for (p in list) {
            val existing = store.profiles().firstOrNull { it.name == p.optString("name") }
            if (existing != null && !store.isOpen(existing.id)) throw CoreError(Err.PROFILE_LOCKED, detail = existing.name)
        }
        for (p in list) {
            val name = p.optString("name").trim().take(60).ifEmpty { "Restored" }
            val profile = store.profiles().firstOrNull { it.name == name }
                ?: store.createProfile(name, p.optInt("color"), null).also { createdProfiles++ }
            val d = store.data(profile.id)
            for (k in p.optJSONArray("keys").objects()) {
                val key = runCatching { pgp.parseKey(k.getString("key").toByteArray()) }.getOrNull() ?: continue
                val fp = pgp.fingerprint(key)
                when (api.mergeInto(d, fp, key, "profile", note = k.optString("note"))) {
                    1 -> added++
                    2 -> updated++
                }
                val rev = if (k.isNull("rev")) null else k.optString("rev").ifEmpty { null }
                d.keys.firstOrNull { it.fp == fp }?.let { e -> if (e.revocation == null && rev != null) e.revocation = rev }
            }
            for (c in p.optJSONArray("contacts").objects()) {
                val cert = runCatching { pgp.parseCert(c.getString("cert").toByteArray()) }.getOrNull() ?: continue
                when (api.mergeInto(d, pgp.fingerprint(cert), pgp.publicPart(cert), "profile", c.optBoolean("verified"), c.optString("note"))) {
                    1 -> added++
                    2 -> updated++
                }
            }
            val def = if (p.isNull("default")) null else p.optString("default")
            if (d.defaultKey == null && def != null && d.keys.any { it.fp == def }) d.defaultKey = def
            store.saveProfileData(profile.id)
        }
        val shared = b.optJSONArray("shared").objects()
        if (shared.isNotEmpty()) {
            val d = store.data(store.activeId)
            for (c in shared) {
                val cert = runCatching { pgp.parseCert(c.getString("cert").toByteArray()) }.getOrNull() ?: continue
                when (api.mergeInto(d, pgp.fingerprint(cert), pgp.publicPart(cert), "shared", c.optBoolean("verified"), c.optString("note"))) {
                    1 -> added++
                    2 -> updated++
                }
            }
            store.saveProfileData(store.activeId)
            store.saveShared()
        }
        return mapOf("added" to added, "updated" to updated, "profiles" to createdProfiles)
    }

    private fun read(input: String, password: String): JSONObject {
        val info = try {
            api.openStream(input).use { pgp.inspect(it) }
        } catch (e: CoreError) {
            throw CoreError(Err.NOT_BACKUP)
        }
        if (!info.passwordEncrypted) throw CoreError(Err.NOT_BACKUP)
        val buf = LimitedBuffer(MAX_BUNDLE)
        try {
            try {
                api.openStream(input).use { pgp.decrypt(it, buf, emptyList(), password, emptyList()) }
            } catch (e: CoreError) {
                throw if (e.code == Err.BAD_DATA) CoreError(Err.NOT_BACKUP) else e
            }
            val o = try {
                JSONObject(String(buf.toByteArray(), Charsets.UTF_8))
            } catch (e: Exception) {
                throw CoreError(Err.NOT_BACKUP)
            }
            if (o.optString("format") != FORMAT || o.optInt("version") !in 1..VERSION) throw CoreError(Err.NOT_BACKUP)
            return o
        } finally {
            buf.wipe()
        }
    }

    private fun keyJson(e: KeyEntry) = JSONObject()
        .put("key", pgp.armor(pgp.parseKey(e.data)))
        .put("rev", e.revocation ?: JSONObject.NULL)
        .put("note", e.note)
        .put("added", e.added)

    private fun contactJson(e: ContactEntry) = JSONObject()
        .put("cert", pgp.armor(pgp.parseCert(e.data)))
        .put("verified", e.verified)
        .put("note", e.note)
        .put("added", e.added)

    companion object {
        const val FORMAT = "shen-backup"
        const val VERSION = 1
        private const val MAX_BUNDLE = 64L * 1024 * 1024
    }
}
