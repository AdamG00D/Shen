package com.adam.shen.core

import org.bouncycastle.openpgp.api.OpenPGPCertificate
import org.bouncycastle.openpgp.api.OpenPGPKey
import org.pgpainless.key.util.RevocationAttributes
import java.io.ByteArrayInputStream
import java.io.InputStream
import java.io.OutputStream
import java.util.Date

/** فتح / إنشاء ملفات (على أندرويد: content:// URIs من الـ Storage Access Framework). */
interface Streams {
    fun open(uri: String): InputStream
    fun create(uri: String): OutputStream

    /** يمسح ملف ناتج (لما فك التشفير يفشل في النص). */
    fun delete(uri: String)
}

/**
 * الواجهة الوحيدة بين Dart والـ core: `call(method, args)` بترجع أنواع بسيطة (Map / List / String / Long...)
 * تعدّي من MethodChannel. كل الأخطاء [CoreError] بكود بس — من غير تفاصيل حساسة.
 *
 * مش thread-safe: أندرويد بينادي كل حاجة من thread واحد ([com.adam.shen.CoreChannel]).
 */
class Api(
    val vault: Vault,
    private val streams: Streams,
    strength: KdfStrength = KdfStrength.STANDARD,
    private val now: () -> Long = System::currentTimeMillis,
) {
    val pgp = Pgp()
    val store = Store(vault, strength)
    private val backup = Backup(this)
    private val passCache = PassCache(now)

    fun call(method: String, a: Map<String, Any?>): Any? {
        if (method !in OPEN_METHODS && !vault.isUnlocked) throw CoreError(Err.LOCKED)
        return when (method) {
            // ---------- الخزنة ----------
            "status" -> mapOf("exists" to vault.exists, "unlocked" to vault.isUnlocked, "bio" to (vault.exists && vault.bioBlob != null))
            "setup" -> setup(a.str("password"), a.str("profileName"), a.int("color"))
            "unlock" -> unlock(a.str("password"))
            "lock" -> lock()
            "changeMasterPassword" -> vault.changePassword(a.str("old"), a.str("new")).let { null }
            "verifyMasterPassword" -> vault.verifyPassword(a.str("password"))
            "wipeAll" -> wipeAll(a.str("password"))
            "setPassCache" -> passCache.setMinutes(a.int("minutes")).let { null }

            // ---------- البروفايلات ----------
            "profiles" -> profiles()
            "createProfile" -> store.createProfile(a.str("name"), a.int("color"), a.strOrNull("password")).id
            "updateProfile" -> store.updateProfile(a.str("id"), a.str("name"), a.int("color")).let { null }
            "deleteProfile" -> deleteProfile(a.str("id"), a.str("password"))
            "setActiveProfile" -> store.setActive(a.str("id")).let { null }
            "unlockProfile" -> store.unlockProfile(a.str("id"), a.str("password")).let { null }
            "lockProfile" -> store.lockProfile(a.str("id")).also { passCache.clear() }.let { null }
            "setProfilePassword" -> store.setProfilePassword(a.str("id"), a.strOrNull("password")).let { null }

            // ---------- مفاتيحي ----------
            "keys" -> keys(a.str("profile"))
            "generateKey" -> generateKey(a)
            "setDefaultKey" -> setDefaultKey(a.str("profile"), a.str("fp"))
            "needsPassphrase" -> needsPassphrase(a.str("profile"), a.str("fp"))
            "checkKeyPassphrase" -> pgp.checkPassphrase(myKey(a.str("profile"), a.str("fp")), a.strOrNull("passphrase"))
            "changeKeyPassphrase" -> editKey(a) { k, p -> pgp.changePassphrase(k, p, a.strOrNull("new")) }.also { passCache.forget(a.str("fp")) }
            "setKeyExpiry" -> editKey(a) { k, p -> pgp.setExpiry(k, p, a.longOrNull("expires")?.let(::Date)) }
            "addUserId" -> editKey(a) { k, p -> pgp.addUserId(k, p, cleanUserId(a.str("userId"))) }
            "revokeKey" -> editKey(a) { k, p -> pgp.revoke(k, p, reason(a.str("reason")), a.strOrNull("description").orEmpty().take(500)) }
            "deleteKey" -> deleteKey(a.str("profile"), a.str("fp"), a.str("password"))
            "exportPublic" -> exportPublic(a.str("profile"), a.strList("fps"))
            "exportSecret" -> exportSecret(a.str("profile"), a.str("fp"), a.str("password"))
            "revocationCert" -> revocationCert(a.str("profile"), a.str("fp"), a.str("password"))

            // ---------- جهات الاتصال ----------
            "contacts" -> contacts(a.str("profile"))
            "previewImport" -> previewImport(a.str("profile"), a.bytes("data"))
            "importKeys" -> importKeys(a.str("profile"), a.bytes("data"), a.str("scope"), a.strListOrNull("fps"))
            "setContactScope" -> setContactScope(a.str("profile"), a.str("fp"), a.str("scope"))
            "setContactVerified" -> updateContact(a.str("profile"), a.str("fp")) { it.verified = a.bool("verified") }
            "setNote" -> setNote(a.str("profile"), a.str("fp"), a.str("note"))
            "deleteContact" -> deleteContact(a.str("profile"), a.str("fp"))
            "certifyContact" -> certifyContact(a)
            "findFingerprint" -> findFingerprint(a.str("profile"), a.str("fp"))

            // ---------- نصوص ----------
            "inspect" -> inspect(a.str("profile"), a.bytes("data"))
            "encryptText" -> String(encrypt(a, ByteArrayInputStream(textBytes(a.str("text")))), Charsets.UTF_8)
            "encryptTextWithPassword" -> encryptTextWithPassword(a.str("text"), a.str("password"))
            "decryptText" -> decryptText(a)
            "signText" -> signText(a)
            "verifyText" -> verifyText(a)

            // ---------- ملفات ----------
            "inspectFile" -> streams.open(a.str("in")).use { inspectStream(a.str("profile"), it) }
            "encryptFile" -> encryptFile(a)
            "decryptFile" -> decryptFile(a)
            "signFile" -> signFile(a)
            "verifyFile" -> verifyFile(a)

            // ---------- النسخ الاحتياطي ----------
            "exportBackup" -> backup.export(a.strOrNull("profile"), a.str("password"), a.str("out"))
            "previewBackup" -> backup.preview(a.str("in"), a.str("password"))
            "importBackup" -> backup.import(a.str("in"), a.str("password"))

            else -> throw CoreError(Err.INVALID, detail = "unknown method")
        }
    }

    // ================= الخزنة =================

    private fun setup(password: String, profileName: String, color: Int): Any? {
        vault.create(password)
        store.load()
        store.createProfile(profileName, color, null)
        return null
    }

    private fun unlock(password: String): Any? {
        vault.unlock(password)
        loadOrLock()
        return null
    }

    /** بعد الفتح بالبصمة. */
    fun unlockWithMasterKey(mk: ByteArray) {
        vault.unlockWithMasterKey(mk)
        loadOrLock()
    }

    private fun loadOrLock() {
        try {
            store.load()
        } catch (e: Exception) {
            lock()
            throw if (e is CoreError) e else CoreError(Err.BAD_DATA)
        }
    }

    fun lock(): Any? {
        passCache.clear()
        store.close()
        vault.lock()
        return null
    }

    private fun wipeAll(password: String): Any? {
        if (!vault.verifyPassword(password)) throw CoreError(Err.WRONG_PASSWORD)
        passCache.clear()
        store.close()
        vault.destroy()
        return null
    }

    // ================= البروفايلات =================

    private fun profiles(): List<Map<String, Any?>> = store.profiles().map { p ->
        val open = store.isOpen(p.id)
        mapOf(
            "id" to p.id,
            "name" to p.name,
            "color" to p.color,
            "hasPassword" to p.hasPassword,
            "open" to open,
            "active" to (p.id == store.activeId),
            "keys" to if (open) store.data(p.id).keys.size else null,
            "contacts" to if (open) store.data(p.id).contacts.size else null,
        )
    }

    private fun deleteProfile(id: String, password: String): Any? {
        if (!vault.verifyPassword(password)) throw CoreError(Err.WRONG_PASSWORD)
        store.deleteProfile(id)
        return null
    }

    // ================= مفاتيحي =================

    private fun keys(profile: String): List<Map<String, Any?>> {
        val d = store.data(profile)
        return d.keys.mapNotNull { e ->
            val k = runCatching { pgp.parseKey(e.data) }.getOrNull() ?: return@mapNotNull null
            pgp.summary(k) + mapOf(
                "note" to e.note,
                "added" to e.added,
                "hasRevocation" to (e.revocation != null),
                "default" to (d.defaultKey == e.fp),
                "cached" to passCache.has(e.fp),
            )
        }
    }

    private fun generateKey(a: Map<String, Any?>): Map<String, Any?> {
        val profile = a.str("profile")
        val d = store.data(profile)
        val uid = buildUserId(a.str("name"), a.strOrNull("email"), a.strOrNull("comment"))
        val pass = a.strOrNull("passphrase")?.ifEmpty { null }
        val algo = when (a.strOrNull("algo") ?: "cv25519") {
            "cv25519" -> KeyAlgo.CV25519
            "rsa4096" -> KeyAlgo.RSA4096
            "v6" -> KeyAlgo.V6
            else -> throw CoreError(Err.INVALID)
        }
        val expires = a.longOrNull("expires")?.let(::Date)
        if (expires != null && expires.time <= now()) throw CoreError(Err.INVALID)
        val key = pgp.generate(uid, pass, algo, expires)
        val fp = pgp.fingerprint(key)
        val rev = pgp.revocationCertificate(key, pass)
        d.keys += KeyEntry(fp, pgp.encode(key), rev, now())
        if (d.defaultKey == null || d.keys.none { it.fp == d.defaultKey }) d.defaultKey = fp
        store.saveProfileData(profile)
        return pgp.summary(key) + mapOf("default" to (d.defaultKey == fp), "hasRevocation" to true)
    }

    private fun setDefaultKey(profile: String, fp: String): Any? {
        val d = store.data(profile)
        if (d.keys.none { it.fp == fp }) throw CoreError(Err.NOT_FOUND)
        d.defaultKey = fp
        store.saveProfileData(profile)
        return null
    }

    private fun myKey(profile: String, fp: String): OpenPGPKey {
        val e = store.data(profile).keys.firstOrNull { it.fp == fp } ?: throw CoreError(Err.NOT_FOUND)
        return pgp.parseKey(e.data)
    }

    /** false = المفتاح ملوش كلمة سر، أو كلمة سره محفوظة مؤقتاً. */
    private fun needsPassphrase(profile: String, fp: String): Boolean {
        val k = myKey(profile, fp)
        if (!pgp.isProtected(k)) return false
        return passCache.get(fp) == null
    }

    /** كلمة السر من المستخدم، أو المحفوظة مؤقتاً. لو اشتغلت بتتحفظ (لو الحفظ المؤقت مفعّل). */
    private fun passFor(key: OpenPGPKey, given: String?): String? {
        val fp = pgp.fingerprint(key)
        if (!pgp.isProtected(key)) return null
        val p = given?.ifEmpty { null } ?: passCache.get(fp) ?: throw CoreError(Err.WRONG_PASSWORD)
        if (!pgp.checkPassphrase(key, p)) {
            passCache.forget(fp)
            throw CoreError(Err.WRONG_PASSWORD)
        }
        passCache.put(fp, p)
        return p
    }

    private fun editKey(a: Map<String, Any?>, edit: (OpenPGPKey, String?) -> OpenPGPKey): Map<String, Any?> {
        val profile = a.str("profile")
        val fp = a.str("fp")
        val e = store.data(profile).keys.firstOrNull { it.fp == fp } ?: throw CoreError(Err.NOT_FOUND)
        val key = pgp.parseKey(e.data)
        val updated = edit(key, passFor(key, a.strOrNull("passphrase")))
        e.data = pgp.encode(updated)
        store.saveProfileData(profile)
        return pgp.summary(updated)
    }

    private fun deleteKey(profile: String, fp: String, password: String): Any? {
        if (!vault.verifyPassword(password)) throw CoreError(Err.WRONG_PASSWORD)
        val d = store.data(profile)
        if (!d.keys.removeAll { it.fp == fp }) throw CoreError(Err.NOT_FOUND)
        if (d.defaultKey == fp) d.defaultKey = d.keys.firstOrNull()?.fp
        passCache.forget(fp)
        store.saveProfileData(profile)
        return null
    }

    /** المفاتيح العامة (من مفاتيحي أو جهات الاتصال) في ملف .asc واحد. */
    private fun exportPublic(profile: String, fps: List<String>): String {
        if (fps.isEmpty()) throw CoreError(Err.INVALID)
        val certs = fps.map { fp ->
            val mine = store.data(profile).keys.firstOrNull { it.fp == fp }
            if (mine != null) pgp.publicPart(pgp.parseKey(mine.data)) else pgp.parseCert(contactEntry(profile, fp).second.data)
        }
        return pgp.armorAll(certs)
    }

    /** المفتاح السري (لسه متشفّر بكلمة سره). محتاج كلمة السر الرئيسية. */
    private fun exportSecret(profile: String, fp: String, password: String): String {
        if (!vault.verifyPassword(password)) throw CoreError(Err.WRONG_PASSWORD)
        return pgp.armor(myKey(profile, fp))
    }

    private fun revocationCert(profile: String, fp: String, password: String): String {
        if (!vault.verifyPassword(password)) throw CoreError(Err.WRONG_PASSWORD)
        val e = store.data(profile).keys.firstOrNull { it.fp == fp } ?: throw CoreError(Err.NOT_FOUND)
        return e.revocation ?: throw CoreError(Err.NOT_FOUND)
    }

    // ================= جهات الاتصال =================

    private fun contacts(profile: String): List<Map<String, Any?>> {
        val own = store.data(profile).contacts.map { it to "profile" }
        val shared = store.shared().filter { s -> own.none { it.first.fp == s.fp } }.map { it to "shared" }
        return (own + shared).mapNotNull { (e, scope) ->
            val c = runCatching { pgp.parseCert(e.data) }.getOrNull() ?: return@mapNotNull null
            pgp.summary(c) + mapOf("scope" to scope, "verified" to e.verified, "note" to e.note, "added" to e.added)
        }
    }

    /** (المكان، الجهة): المكان = "profile" أو "shared". */
    private fun contactEntry(profile: String, fp: String): Pair<String, ContactEntry> {
        store.data(profile).contacts.firstOrNull { it.fp == fp }?.let { return "profile" to it }
        store.shared().firstOrNull { it.fp == fp }?.let { return "shared" to it }
        throw CoreError(Err.NOT_FOUND)
    }

    private fun saveContact(profile: String, where: String) {
        if (where == "shared") store.saveShared() else store.saveProfileData(profile)
    }

    private fun updateContact(profile: String, fp: String, change: (ContactEntry) -> Unit): Any? {
        val (where, e) = contactEntry(profile, fp)
        change(e)
        saveContact(profile, where)
        return null
    }

    private fun setNote(profile: String, fp: String, note: String): Any? {
        val clean = note.take(500)
        store.data(profile).keys.firstOrNull { it.fp == fp }?.let {
            it.note = clean
            store.saveProfileData(profile)
            return null
        }
        return updateContact(profile, fp) { it.note = clean }
    }

    private fun setContactScope(profile: String, fp: String, scope: String): Any? {
        val (where, e) = contactEntry(profile, fp)
        if (scope == where) return null
        when (scope) {
            "shared" -> {
                store.data(profile).contacts.remove(e)
                store.shared() += e
            }
            "profile" -> {
                store.shared().remove(e)
                store.data(profile).contacts += e
            }
            else -> throw CoreError(Err.INVALID)
        }
        store.saveShared()
        store.saveProfileData(profile)
        return null
    }

    private fun deleteContact(profile: String, fp: String): Any? {
        val (where, e) = contactEntry(profile, fp)
        if (where == "shared") store.shared().remove(e) else store.data(profile).contacts.remove(e)
        saveContact(profile, where)
        return null
    }

    private fun certifyContact(a: Map<String, Any?>): Map<String, Any?> {
        val profile = a.str("profile")
        val (where, e) = contactEntry(profile, a.str("fp"))
        val key = myKey(profile, a.str("keyFp"))
        val certified = pgp.certify(key, passFor(key, a.strOrNull("passphrase")), pgp.parseCert(e.data))
        e.data = pgp.encode(certified)
        e.verified = true
        saveContact(profile, where)
        return pgp.summary(certified)
    }

    /** للمسح بالـ QR: البصمة دي تبع مين؟ */
    private fun findFingerprint(profile: String, fp: String): Map<String, Any?>? {
        val clean = fp.uppercase().filter { it.isLetterOrDigit() }
        store.data(profile).keys.firstOrNull { it.fp == clean }?.let { return mapOf("kind" to "key", "fp" to clean) }
        val c = runCatching { contactEntry(profile, clean) }.getOrNull() ?: return null
        return mapOf("kind" to "contact", "fp" to clean, "verified" to c.second.verified, "scope" to c.first)
    }

    private fun previewImport(profile: String, data: ByteArray): List<Map<String, Any?>> {
        val certs = parseImport(data)
        val d = store.data(profile)
        return certs.map { c ->
            val fp = pgp.fingerprint(c)
            val existing = when {
                d.keys.any { it.fp == fp } -> "key"
                d.contacts.any { it.fp == fp } -> "profile"
                store.shared().any { it.fp == fp } -> "shared"
                else -> null
            }
            pgp.summary(c) + mapOf("existing" to existing)
        }
    }

    /**
     * يستورد مفاتيح: السري يروح لمفاتيحي، والعام لجهات الاتصال ([scope]).
     * لو موجود قبل كده بيندمج (صلاحية / إلغاء / هويات جديدة)، ومفيش حاجة بتتمسح.
     */
    private fun importKeys(profile: String, data: ByteArray, scope: String, only: List<String>?): Map<String, Any?> {
        if (scope != "profile" && scope != "shared") throw CoreError(Err.INVALID)
        val d = store.data(profile)
        var added = 0
        var updated = 0
        var unchanged = 0
        for (c in parseImport(data)) {
            val fp = pgp.fingerprint(c)
            if (only != null && fp !in only) continue
            val r = mergeInto(d, fp, c, scope)
            when (r) {
                1 -> added++
                2 -> updated++
                else -> unchanged++
            }
        }
        store.saveProfileData(profile)
        store.saveShared()
        return mapOf("added" to added, "updated" to updated, "unchanged" to unchanged)
    }

    /** 0 = مفيش جديد، 1 = اتضاف، 2 = اتحدّث. */
    internal fun mergeInto(d: ProfileData, fp: String, c: OpenPGPCertificate, scope: String, verified: Boolean = false, note: String = ""): Int {
        val mine = d.keys.firstOrNull { it.fp == fp }
        if (c is OpenPGPKey) {
            if (mine != null) {
                val merged = pgp.mergeIntoKey(pgp.parseKey(mine.data), c)
                return replaceIfChanged(mine.data, pgp.encode(merged)) { mine.data = it }
            }
            d.keys += KeyEntry(fp, pgp.encode(c), null, now(), note)
            if (d.defaultKey == null) d.defaultKey = fp
            // لو كان جهة اتصال قبل كده يبقى خلاص ده مفتاحي
            d.contacts.removeAll { it.fp == fp }
            return 1
        }
        if (mine != null) {
            val merged = pgp.mergeIntoKey(pgp.parseKey(mine.data), c)
            return replaceIfChanged(mine.data, pgp.encode(merged)) { mine.data = it }
        }
        val existing = d.contacts.firstOrNull { it.fp == fp } ?: store.shared().firstOrNull { it.fp == fp }
        if (existing != null) {
            val merged = pgp.merge(pgp.parseCert(existing.data), c)
            if (verified) existing.verified = true
            return replaceIfChanged(existing.data, pgp.encode(merged)) { existing.data = it }
        }
        val e = ContactEntry(fp, pgp.encode(pgp.publicPart(c)), verified, now(), note)
        if (scope == "shared") store.shared() += e else d.contacts += e
        return 1
    }

    private inline fun replaceIfChanged(old: ByteArray, new: ByteArray, set: (ByteArray) -> Unit): Int {
        if (old.contentEquals(new)) return 0
        set(new)
        return 2
    }

    private fun parseImport(data: ByteArray): List<OpenPGPCertificate> {
        if (data.size > MAX_IMPORT) throw CoreError(Err.TOO_LARGE)
        val certs = pgp.parse(data)
        if (certs.size > MAX_CERTS) throw CoreError(Err.TOO_LARGE)
        return certs
    }

    // ================= التشفير والفك =================

    /** كل الشهادات اللي ممكن نتحقق بيها من توقيع: مفاتيحي + جهات الاتصال (البروفايل + المشتركة). */
    private fun knownCerts(profile: String): List<OpenPGPCertificate> {
        val d = store.data(profile)
        val list = mutableListOf<OpenPGPCertificate>()
        d.keys.forEach { runCatching { list += pgp.publicPart(pgp.parseKey(it.data)) } }
        (d.contacts + store.shared()).forEach { runCatching { list += pgp.parseCert(it.data) } }
        return list
    }

    private fun recipientCerts(profile: String, fps: List<String>): List<OpenPGPCertificate> = fps.distinct().map { fp ->
        store.data(profile).keys.firstOrNull { it.fp == fp }?.let { return@map pgp.publicPart(pgp.parseKey(it.data)) }
        pgp.parseCert(contactEntry(profile, fp).second.data)
    }

    /** بيشفّر لـ [recipients] + (لو [self]) مفتاحي الافتراضي، ويوقّع لو [signWith]. */
    private fun encryptTo(a: Map<String, Any?>, input: InputStream, output: OutputStream, armor: Boolean, fileName: String?) {
        val profile = a.str("profile")
        val fps = a.strList("recipients").toMutableList()
        val signFp = a.strOrNull("signWith")
        if (a.boolOr("self", true)) {
            val self = signFp ?: store.data(profile).defaultKey
            if (self != null) fps += self
        }
        val recipients = recipientCerts(profile, fps)
        val signer = signFp?.let { myKey(profile, it) }
        val pass = signer?.let { passFor(it, a.strOrNull("passphrase")) }
        pgp.encrypt(input, output, recipients, signer, pass, armor, fileName)
    }

    private fun encrypt(a: Map<String, Any?>, input: InputStream): ByteArray {
        val out = LimitedBuffer(MAX_TEXT_OUT)
        encryptTo(a, input, out, armor = true, fileName = null)
        return out.toByteArray()
    }

    private fun encryptTextWithPassword(text: String, password: String): String {
        val out = LimitedBuffer(MAX_TEXT_OUT)
        // الصيغة المتوافقة: اللي هيستلم ممكن يكون عنده gpg / كيلوباترا
        pgp.encryptWithPassword(ByteArrayInputStream(textBytes(text)), out, password, armor = true, modern = false)
        return String(out.toByteArray(), Charsets.UTF_8)
    }

    private fun inspect(profile: String, data: ByteArray): Map<String, Any?> {
        if (data.size > MAX_TEXT_IN) throw CoreError(Err.TOO_LARGE)
        val head = String(data, 0, minOf(data.size, 4096), Charsets.UTF_8)
        if ("-----BEGIN PGP SIGNED MESSAGE-----" in head) return mapOf("kind" to "clearsigned")
        if ("-----BEGIN PGP PUBLIC KEY BLOCK-----" in head || "-----BEGIN PGP PRIVATE KEY BLOCK-----" in head) {
            return mapOf("kind" to "keys")
        }
        if ("-----BEGIN PGP SIGNATURE-----" in head) return mapOf("kind" to "signature")
        return inspectStream(profile, ByteArrayInputStream(data))
    }

    private fun inspectStream(profile: String, input: InputStream): Map<String, Any?> {
        val info = try {
            pgp.inspect(input)
        } catch (e: CoreError) {
            return mapOf("kind" to "unknown")
        }
        if (!info.encrypted) return mapOf("kind" to "signed")
        val mine = store.data(profile).keys.mapNotNull { e -> runCatching { pgp.parseKey(e.data) }.getOrNull() }
        val recipients = info.recipientKeyIds.map { id ->
            val k = mine.firstOrNull { k -> k.keys.any { matchesId(it.pgpPublicKey.fingerprint, id) } }
            val other = if (k == null) otherProfileFor(profile, id) else null
            mapOf(
                "keyId" to id,
                "fp" to k?.let { pgp.fingerprint(it) },
                "uid" to k?.let { pgp.summary(it)["primaryUid"] },
                "otherProfile" to other,
            )
        }
        return mapOf("kind" to "encrypted", "recipients" to recipients, "password" to info.passwordEncrypted)
    }

    /** الرسالة دي ممكن تكون لمفتاح في بروفايل تاني مفتوح — نقول للمستخدم يروح له. */
    private fun otherProfileFor(current: String, keyId: String): String? {
        for (p in store.profiles()) {
            if (p.id == current || !store.isOpen(p.id)) continue
            for (e in store.data(p.id).keys) {
                val k = runCatching { pgp.parseKey(e.data) }.getOrNull() ?: continue
                if (k.keys.any { matchesId(it.pgpPublicKey.fingerprint, keyId) }) return p.name
            }
        }
        return null
    }

    private fun matchesId(fp: ByteArray, keyId: String): Boolean {
        if (keyId == "0000000000000000") return false
        val hex = Bytes.hex(fp)
        return if (fp.size == 32) hex.startsWith(keyId) else hex.endsWith(keyId)
    }

    /** المفاتيح اللي هنجرب نفك بيها: لو [keyFp] محدد يبقى هو بس (بكلمة سره)، غير كده اللي من غير كلمة سر / محفوظة. */
    private fun decryptionKeys(profile: String, keyFp: String?, passphrase: String?): List<Pair<OpenPGPKey, String?>> {
        if (keyFp != null) {
            val k = myKey(profile, keyFp)
            return listOf(k to passFor(k, passphrase))
        }
        return store.data(profile).keys.mapNotNull { e ->
            val k = runCatching { pgp.parseKey(e.data) }.getOrNull() ?: return@mapNotNull null
            when {
                !pgp.isProtected(k) -> k to null
                passCache.get(e.fp) != null -> k to passCache.get(e.fp)
                else -> null
            }
        }
    }

    private fun decryptText(a: Map<String, Any?>): Map<String, Any?> {
        val profile = a.str("profile")
        val data = a.bytes("data")
        if (data.size > MAX_TEXT_IN) throw CoreError(Err.TOO_LARGE)
        val out = LimitedBuffer(MAX_TEXT_OUT)
        try {
            val r = pgp.decrypt(
                ByteArrayInputStream(data),
                out,
                decryptionKeys(profile, a.strOrNull("keyFp"), a.strOrNull("passphrase")),
                a.strOrNull("password"),
                knownCerts(profile),
            )
            return mapOf(
                "text" to String(out.toByteArray(), Charsets.UTF_8),
                "fileName" to r.fileName,
                "signatures" to describe(profile, r.signatures),
            )
        } finally {
            out.wipe()
        }
    }

    private fun signText(a: Map<String, Any?>): String {
        val profile = a.str("profile")
        val key = myKey(profile, a.str("keyFp"))
        val mode = if (a.strOrNull("mode") == "detached") SignMode.DETACHED else SignMode.CLEAR
        val out = LimitedBuffer(MAX_TEXT_OUT)
        pgp.sign(ByteArrayInputStream(textBytes(a.str("text"))), out, key, passFor(key, a.strOrNull("passphrase")), mode, armor = true)
        return String(out.toByteArray(), Charsets.UTF_8)
    }

    private fun verifyText(a: Map<String, Any?>): Map<String, Any?> {
        val profile = a.str("profile")
        val data = a.bytes("data")
        if (data.size > MAX_TEXT_IN) throw CoreError(Err.TOO_LARGE)
        val sig = a.bytesOrNull("signature")
        val out = LimitedBuffer(MAX_TEXT_OUT)
        val sigs = pgp.verify(ByteArrayInputStream(data), if (sig == null) out else null, sig?.let(::ByteArrayInputStream), knownCerts(profile))
        return mapOf(
            "text" to if (sig == null) String(out.toByteArray(), Charsets.UTF_8) else null,
            "signatures" to describe(profile, sigs),
        )
    }

    /** يضيف اسم صاحب التوقيع وهل اتأكدنا منه. */
    private fun describe(profile: String, sigs: List<SigInfo>): List<Map<String, Any?>> = sigs.map { s ->
        var name: String? = null
        var verified = false
        var mine = false
        if (s.fp != null) {
            store.data(profile).keys.firstOrNull { it.fp == s.fp }?.let { e ->
                mine = true
                verified = true
                name = runCatching { pgp.summary(pgp.parseKey(e.data))["primaryUid"] as String? }.getOrNull()
            }
            if (!mine) {
                runCatching { contactEntry(profile, s.fp).second }.getOrNull()?.let { e ->
                    verified = e.verified
                    name = runCatching { pgp.summary(pgp.parseCert(e.data))["primaryUid"] as String? }.getOrNull()
                }
            }
        }
        s.toMap() + mapOf("name" to name, "verified" to verified, "mine" to mine)
    }

    // ================= ملفات =================

    private fun encryptFile(a: Map<String, Any?>): Any? {
        val out = a.str("out")
        withOutput(out) { o ->
            streams.open(a.str("in")).use { i ->
                if (a.strOrNull("password") != null) {
                    pgp.encryptWithPassword(i, o, a.str("password"), a.boolOr("armor", false), modern = false)
                } else {
                    encryptTo(a, i, o, a.boolOr("armor", false), a.strOrNull("fileName"))
                }
            }
        }
        return null
    }

    private fun decryptFile(a: Map<String, Any?>): Map<String, Any?> {
        val profile = a.str("profile")
        var result: DecryptResult? = null
        withOutput(a.str("out")) { o ->
            streams.open(a.str("in")).use { i ->
                result = pgp.decrypt(
                    i,
                    o,
                    decryptionKeys(profile, a.strOrNull("keyFp"), a.strOrNull("passphrase")),
                    a.strOrNull("password"),
                    knownCerts(profile),
                )
            }
        }
        return mapOf("fileName" to result!!.fileName, "signatures" to describe(profile, result!!.signatures))
    }

    private fun signFile(a: Map<String, Any?>): Any? {
        val profile = a.str("profile")
        val key = myKey(profile, a.str("keyFp"))
        val pass = passFor(key, a.strOrNull("passphrase"))
        withOutput(a.str("out")) { o ->
            streams.open(a.str("in")).use { i -> pgp.sign(i, o, key, pass, SignMode.DETACHED, a.boolOr("armor", true)) }
        }
        return null
    }

    /** [a] فيه `sig` = توقيع منفصل، أو `out` = ملف موقّع جوه نفسه (gpg --sign) والمحتوى بيتكتب في out. */
    private fun verifyFile(a: Map<String, Any?>): List<Map<String, Any?>> {
        val profile = a.str("profile")
        if (a.strOrNull("sig") == null) {
            var res: List<SigInfo> = emptyList()
            withOutput(a.str("out")) { o ->
                streams.open(a.str("in")).use { i -> res = pgp.verify(i, o, null, knownCerts(profile)) }
            }
            return describe(profile, res)
        }
        val sig = streams.open(a.str("sig")).use { it.readNBytes(MAX_IMPORT + 1) }
        if (sig.size > MAX_IMPORT) throw CoreError(Err.TOO_LARGE)
        val res = streams.open(a.str("in")).use { i -> pgp.verify(i, null, ByteArrayInputStream(sig), knownCerts(profile)) }
        return describe(profile, res)
    }

    /** لو العملية فشلت في النص (باسورد غلط، ملف متلعب فيه...) الناتج اللي اتكتب جزء منه بيتمسح. */
    private fun withOutput(uri: String, block: (OutputStream) -> Unit) {
        var ok = false
        try {
            streams.create(uri).use { block(it) }
            ok = true
        } catch (e: CoreError) {
            throw e
        } catch (e: java.io.IOException) {
            throw CoreError(Err.IO)
        } finally {
            if (!ok) runCatching { streams.delete(uri) }
        }
    }

    internal fun openStream(uri: String) = streams.open(uri)
    internal fun createStream(uri: String) = streams.create(uri)
    internal fun deleteStream(uri: String) = streams.delete(uri)
    internal fun nowMs() = now()

    // ================= مساعدات =================

    private fun buildUserId(name: String, email: String?, comment: String?): String {
        val n = name.trim()
        val e = email?.trim().orEmpty()
        val c = comment?.trim().orEmpty()
        if (n.isEmpty() && e.isEmpty()) throw CoreError(Err.INVALID)
        if (e.isNotEmpty() && !EMAIL.matches(e)) throw CoreError(Err.INVALID)
        if (listOf(n, c).any { it.contains('<') || it.contains('>') || it.contains('(') || it.contains(')') }) {
            throw CoreError(Err.INVALID)
        }
        val uid = buildString {
            append(n)
            if (c.isNotEmpty()) append(" ($c)")
            if (e.isNotEmpty()) append(if (n.isEmpty() && c.isEmpty()) "<$e>" else " <$e>")
        }
        return cleanUserId(uid)
    }

    private fun cleanUserId(uid: String): String {
        val u = uid.trim()
        if (u.isEmpty() || u.length > 256 || u.any { it.isISOControl() }) throw CoreError(Err.INVALID)
        return u
    }

    private fun reason(r: String) = when (r) {
        "compromised" -> RevocationAttributes.Reason.KEY_COMPROMISED
        "superseded" -> RevocationAttributes.Reason.KEY_SUPERSEDED
        "retired" -> RevocationAttributes.Reason.KEY_RETIRED
        else -> RevocationAttributes.Reason.NO_REASON
    }

    private fun textBytes(text: String): ByteArray {
        val b = text.toByteArray(Charsets.UTF_8)
        if (b.size > MAX_TEXT_IN) throw CoreError(Err.TOO_LARGE)
        return b
    }

    companion object {
        /** الحاجات اللي تتنادي والخزنة مقفولة. */
        private val OPEN_METHODS = setOf("status", "setup", "unlock", "lock", "setPassCache")

        const val MAX_TEXT_IN = 10 * 1024 * 1024
        const val MAX_TEXT_OUT = 16L * 1024 * 1024
        const val MAX_IMPORT = 8 * 1024 * 1024
        const val MAX_CERTS = 2000
        private val EMAIL = Regex("^[^\\s@<>()]+@[^\\s@<>()]+\\.[^\\s@<>()]+$")
    }
}

/** كلمات سر المفاتيح في الذاكرة لمدة محدودة (الافتراضي: مبنحفظش خالص). */
class PassCache(private val now: () -> Long) {
    private val map = mutableMapOf<String, Pair<String, Long>>()
    private var minutes = 0

    fun setMinutes(m: Int) {
        minutes = m.coerceIn(0, 60)
        if (minutes == 0) clear()
    }

    fun put(fp: String, pass: String) {
        if (minutes > 0) map[fp] = pass to now() + minutes * 60_000L
    }

    fun get(fp: String): String? {
        val e = map[fp] ?: return null
        if (now() > e.second) {
            map.remove(fp)
            return null
        }
        return e.first
    }

    fun has(fp: String) = get(fp) != null

    fun forget(fp: String) {
        map.remove(fp)
    }

    fun clear() = map.clear()
}

// ---------- قراية المعاملات من Dart ----------

internal fun Map<String, Any?>.str(k: String): String = this[k] as? String ?: throw CoreError(Err.INVALID, detail = k)
internal fun Map<String, Any?>.strOrNull(k: String): String? = this[k] as? String
internal fun Map<String, Any?>.int(k: String): Int = (this[k] as? Number)?.toInt() ?: 0
internal fun Map<String, Any?>.longOrNull(k: String): Long? = (this[k] as? Number)?.toLong()
internal fun Map<String, Any?>.bool(k: String): Boolean = this[k] as? Boolean ?: false
internal fun Map<String, Any?>.boolOr(k: String, d: Boolean): Boolean = this[k] as? Boolean ?: d
internal fun Map<String, Any?>.strList(k: String): List<String> = (this[k] as? List<*>)?.filterIsInstance<String>() ?: emptyList()
internal fun Map<String, Any?>.strListOrNull(k: String): List<String>? = (this[k] as? List<*>)?.filterIsInstance<String>()
internal fun Map<String, Any?>.bytes(k: String): ByteArray = bytesOrNull(k) ?: throw CoreError(Err.INVALID, detail = k)
internal fun Map<String, Any?>.bytesOrNull(k: String): ByteArray? = when (val v = this[k]) {
    is ByteArray -> v
    is String -> v.toByteArray(Charsets.UTF_8)
    else -> null
}
