package com.adam.shen.core

import org.json.JSONArray
import org.json.JSONObject

/** مفتاح من مفاتيحي (فيه الجزء السري، ولسه متشفّر بكلمة سر المفتاح نفسه). */
class KeyEntry(
    val fp: String,
    var data: ByteArray,
    /** شهادة إلغاء جاهزة (armored) — اتعملت وقت إنشاء المفتاح. */
    var revocation: String?,
    val added: Long,
    var note: String = "",
) {
    fun toJson(): JSONObject = JSONObject()
        .put("fp", fp)
        .put("data", Bytes.b64(data))
        .put("rev", revocation ?: JSONObject.NULL)
        .put("added", added)
        .put("note", note)

    companion object {
        fun fromJson(o: JSONObject) = KeyEntry(
            o.getString("fp"),
            Bytes.unb64(o.getString("data")),
            if (o.isNull("rev")) null else o.getString("rev"),
            o.optLong("added"),
            o.optString("note"),
        )
    }
}

/** جهة اتصال = المفتاح العام بتاع حد تاني. */
class ContactEntry(
    val fp: String,
    var data: ByteArray,
    /** المستخدم اتأكد من البصمة (وش لوش / QR). */
    var verified: Boolean,
    val added: Long,
    var note: String = "",
) {
    fun toJson(): JSONObject = JSONObject()
        .put("fp", fp)
        .put("data", Bytes.b64(data))
        .put("verified", verified)
        .put("added", added)
        .put("note", note)

    companion object {
        fun fromJson(o: JSONObject) = ContactEntry(
            o.getString("fp"),
            Bytes.unb64(o.getString("data")),
            o.optBoolean("verified"),
            o.optLong("added"),
            o.optString("note"),
        )
    }
}

class ProfileData(val keys: MutableList<KeyEntry> = mutableListOf(), val contacts: MutableList<ContactEntry> = mutableListOf()) {
    fun toJson(): JSONObject = JSONObject()
        .put("keys", JSONArray(keys.map { it.toJson() }))
        .put("contacts", JSONArray(contacts.map { it.toJson() }))

    companion object {
        fun fromJson(o: JSONObject) = ProfileData(
            o.optJSONArray("keys").objects().map(KeyEntry::fromJson).toMutableList(),
            o.optJSONArray("contacts").objects().map(ContactEntry::fromJson).toMutableList(),
        )
    }
}

class Profile(
    val id: String,
    var name: String,
    var color: Int,
    val created: Long,
    /** مفتاح البيانات (DEK) متشفّر بالمفتاح الرئيسي — ولو للبروفايل كلمة سر، متشفّر بيها كمان جوه. */
    var dek: String,
    /** != null يعني البروفايل ليه كلمة سر لوحده. */
    var kdf: KdfParams?,
) {
    val hasPassword get() = kdf != null

    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("name", name)
        .put("color", color)
        .put("created", created)
        .put("dek", dek)
        .put("kdf", kdf?.toJson() ?: JSONObject.NULL)

    companion object {
        fun fromJson(o: JSONObject) = Profile(
            o.getString("id"),
            o.getString("name"),
            o.optInt("color"),
            o.optLong("created"),
            o.getString("dek"),
            if (o.isNull("kdf")) null else KdfParams.fromJson(o.getJSONObject("kdf")),
        )
    }
}

/**
 * البروفايلات وبياناتها.
 *
 * ```
 * profiles.bin        قايمة البروفايلات (المفتاح الرئيسي)
 * p/<id>.bin          مفاتيحي + جهات الاتصال الخاصة بالبروفايل ده (مفتاح البروفايل)
 * shared.bin          جهات الاتصال اللي ظاهرة في كل البروفايلات (المفتاح الرئيسي)
 * ```
 * كل ملف ليه AAD فيه اسمه + id البروفايل، فمينفعش حد يبدّل ملف بروفايل بملف بروفايل تاني.
 */
class Store(private val vault: Vault, private val strength: KdfStrength = KdfStrength.STANDARD) {
    private val profiles = mutableListOf<Profile>()
    private val deks = mutableMapOf<String, ByteArray>()
    private val data = mutableMapOf<String, ProfileData>()
    private var shared = mutableListOf<ContactEntry>()
    var activeId: String = ""
        private set
    var loaded = false
        private set

    /** بعد فتح الخزنة: يحمّل البروفايلات ويفتح اللي ملهاش كلمة سر. */
    fun load() {
        close()
        val mk = vault.masterKey()
        val raw = vault.read(PROFILES, AAD_PROFILES, mk)
        if (raw != null) {
            val o = JSONObject(String(raw, Charsets.UTF_8))
            o.getJSONArray("profiles").objects().forEach { profiles += Profile.fromJson(it) }
            activeId = o.optString("active")
        }
        shared = vault.read(SHARED, AAD_SHARED, mk)?.let { bytes ->
            JSONObject(String(bytes, Charsets.UTF_8)).optJSONArray("contacts").objects()
                .map(ContactEntry::fromJson).toMutableList()
        } ?: mutableListOf()
        for (p in profiles) {
            if (!p.hasPassword) openProfile(p, Bytes.unb64(p.dek).let { Aead.open(mk, it, aadDek(p.id)) })
        }
        if (profiles.none { it.id == activeId }) activeId = profiles.firstOrNull()?.id ?: ""
        loaded = true
    }

    /** يقفل كل حاجة ويمسح المفاتيح من الذاكرة. */
    fun close() {
        deks.values.forEach(Bytes::wipe)
        deks.clear()
        data.clear()
        profiles.clear()
        shared = mutableListOf()
        activeId = ""
        loaded = false
    }

    fun profiles(): List<Profile> = profiles.toList()

    fun profile(id: String): Profile = profiles.firstOrNull { it.id == id } ?: throw CoreError(Err.NOT_FOUND)

    fun isOpen(id: String) = data.containsKey(id)

    fun createProfile(name: String, color: Int, password: String?): Profile {
        val clean = cleanName(name)
        val dek = Bytes.random(32)
        val p = Profile(Bytes.randomId(), clean, color, System.currentTimeMillis(), "", null)
        wrapDek(p, dek, password)
        profiles += p
        openProfile(p, dek)
        if (activeId.isEmpty()) activeId = p.id
        saveProfileData(p.id)
        saveProfiles()
        return p
    }

    fun updateProfile(id: String, name: String, color: Int) {
        val p = profile(id)
        p.name = cleanName(name)
        p.color = color
        saveProfiles()
    }

    fun deleteProfile(id: String) {
        profile(id)
        if (profiles.size <= 1) throw CoreError(Err.INVALID)
        profiles.removeAll { it.id == id }
        deks.remove(id)?.let(Bytes::wipe)
        data.remove(id)
        vault.delete(profileFile(id))
        if (activeId == id) activeId = profiles.first().id
        saveProfiles()
    }

    fun setActive(id: String) {
        profile(id)
        activeId = id
        saveProfiles()
    }

    fun unlockProfile(id: String, password: String) {
        val p = profile(id)
        if (isOpen(id)) return
        val kdf = p.kdf ?: throw CoreError(Err.INVALID)
        val inner = Aead.open(vault.masterKey(), Bytes.unb64(p.dek), aadDek(id))
        val pw = Kdf.normalize(password)
        val kek = Kdf.argon2id(pw, kdf)
        Bytes.wipe(pw)
        val dek = try {
            Aead.open(kek, inner, aadProfileDek(id))
        } catch (e: CoreError) {
            throw CoreError(Err.WRONG_PASSWORD)
        } finally {
            Bytes.wipe(kek)
        }
        openProfile(p, dek)
    }

    /** يقفل بروفايل ليه كلمة سر (اللي ملوش بيفضل مفتوح طول ما الخزنة مفتوحة). */
    fun lockProfile(id: String) {
        val p = profile(id)
        if (!p.hasPassword) return
        deks.remove(id)?.let(Bytes::wipe)
        data.remove(id)
    }

    /** يحط / يغيّر / يشيل (null) كلمة سر البروفايل. البروفايل لازم يكون مفتوح. */
    fun setProfilePassword(id: String, password: String?) {
        val p = profile(id)
        val dek = deks[id] ?: throw CoreError(Err.PROFILE_LOCKED)
        wrapDek(p, dek, password)
        saveProfiles()
    }

    fun data(id: String): ProfileData {
        profile(id)
        return data[id] ?: throw CoreError(Err.PROFILE_LOCKED)
    }

    fun shared(): MutableList<ContactEntry> = shared

    fun saveProfileData(id: String) {
        val dek = deks[id] ?: throw CoreError(Err.PROFILE_LOCKED)
        vault.write(profileFile(id), aadData(id), dek, data(id).toJson().toString().toByteArray(Charsets.UTF_8))
    }

    fun saveShared() {
        val o = JSONObject().put("contacts", JSONArray(shared.map { it.toJson() }))
        vault.write(SHARED, AAD_SHARED, vault.masterKey(), o.toString().toByteArray(Charsets.UTF_8))
    }

    /** بيعيد تشفير مفتاح كل بروفايل بالمفتاح الرئيسي (مبيتغيّرش غير لو الخزنة اتعملت من جديد). */
    private fun saveProfiles() {
        val o = JSONObject()
            .put("profiles", JSONArray(profiles.map { it.toJson() }))
            .put("active", activeId)
        vault.write(PROFILES, AAD_PROFILES, vault.masterKey(), o.toString().toByteArray(Charsets.UTF_8))
    }

    private fun openProfile(p: Profile, dek: ByteArray) {
        val raw = vault.read(profileFile(p.id), aadData(p.id), dek)
        data[p.id] = raw?.let { ProfileData.fromJson(JSONObject(String(it, Charsets.UTF_8))) } ?: ProfileData()
        deks[p.id] = dek
    }

    private fun wrapDek(p: Profile, dek: ByteArray, password: String?) {
        var inner = dek
        if (password != null) {
            if (password.length < Vault.MIN_PASSWORD || password.length > 1024) throw CoreError(Err.INVALID)
            val kdf = strength.fresh()
            val pw = Kdf.normalize(password)
            val kek = Kdf.argon2id(pw, kdf)
            Bytes.wipe(pw)
            inner = Aead.seal(kek, dek, aadProfileDek(p.id))
            Bytes.wipe(kek)
            p.kdf = kdf
        } else {
            p.kdf = null
        }
        p.dek = Bytes.b64(Aead.seal(vault.masterKey(), inner, aadDek(p.id)))
    }

    private fun cleanName(name: String): String {
        val n = name.trim()
        if (n.isEmpty() || n.length > 60) throw CoreError(Err.INVALID)
        return n
    }

    companion object {
        private const val PROFILES = "profiles.bin"
        private const val SHARED = "shared.bin"
        private const val AAD_PROFILES = "shen/profiles/v1"
        private const val AAD_SHARED = "shen/shared/v1"
        private fun profileFile(id: String) = "p/$id.bin"
        private fun aadDek(id: String) = "shen/dek/v1|$id"
        private fun aadProfileDek(id: String) = "shen/profile-dek/v1|$id"
        private fun aadData(id: String) = "shen/profile/v1|$id"
    }
}

internal fun JSONArray?.objects(): List<JSONObject> =
    if (this == null) emptyList() else (0 until length()).map { getJSONObject(it) }
