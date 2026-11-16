package com.adam.shen.core

import org.bouncycastle.bcpg.ArmoredOutputStream
import org.bouncycastle.bcpg.S2K
import org.bouncycastle.openpgp.PGPException
import org.bouncycastle.openpgp.PGPSecretKeyRing
import org.bouncycastle.openpgp.PGPSignature
import org.bouncycastle.openpgp.api.MessageEncryptionMechanism
import org.bouncycastle.openpgp.api.OpenPGPCertificate
import org.bouncycastle.openpgp.api.OpenPGPKey
import org.bouncycastle.openpgp.operator.bc.BcPBEKeyEncryptionMethodGenerator
import org.pgpainless.PGPainless
import org.pgpainless.algorithm.AEADAlgorithm
import org.pgpainless.algorithm.AlgorithmSuite
import org.pgpainless.algorithm.Feature
import org.pgpainless.algorithm.CompressionAlgorithm
import org.pgpainless.algorithm.DocumentSignatureType
import org.pgpainless.algorithm.KeyFlag
import org.pgpainless.algorithm.OpenPGPKeyVersion
import org.pgpainless.algorithm.StreamEncoding
import org.pgpainless.algorithm.SymmetricKeyAlgorithm
import org.pgpainless.bouncycastle.extensions.isEncrypted
import org.pgpainless.bouncycastle.extensions.toOpenPGPCertificate
import org.pgpainless.bouncycastle.extensions.unlock
import org.pgpainless.decryption_verification.ConsumerOptions
import org.pgpainless.decryption_verification.MessageInspector
import org.pgpainless.decryption_verification.SignatureVerification
import org.pgpainless.encryption_signing.EncryptionOptions
import org.pgpainless.encryption_signing.ProducerOptions
import org.pgpainless.encryption_signing.SigningOptions
import org.pgpainless.exception.KeyException
import org.pgpainless.exception.MalformedOpenPgpMessageException
import org.pgpainless.exception.MissingDecryptionMethodException
import org.pgpainless.exception.MissingPassphraseException
import org.pgpainless.exception.ModificationDetectionException
import org.pgpainless.exception.WrongPassphraseException
import org.pgpainless.key.generation.KeySpec
import org.pgpainless.key.generation.type.KeyType
import org.pgpainless.key.generation.type.eddsa_legacy.EdDSALegacyCurve
import org.pgpainless.key.generation.type.rsa.RsaLength
import org.pgpainless.key.generation.type.xdh_legacy.XDHLegacySpec
import org.pgpainless.key.protection.SecretKeyRingProtector
import org.pgpainless.key.util.KeyRingUtils
import org.pgpainless.key.util.RevocationAttributes
import org.pgpainless.util.Passphrase
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.security.SecureRandom
import java.util.Date

/** نوع المفتاح الجديد. */
enum class KeyAlgo {
    /** Ed25519 + X25519 بصيغة v4 — الافتراضي، شغال مع gpg وكيلوباترا وأي برنامج. */
    CV25519,

    /** RSA-4096 v4 — للأنظمة القديمة. */
    RSA4096,

    /** Ed25519 + X25519 بصيغة v6 (RFC 9580) — أحدث، بس gpg لسه مبيدعموش. */
    V6,
}

enum class SignMode { CLEAR, DETACHED, INLINE }

enum class SigStatus { GOOD, BAD, UNKNOWN_KEY }

/** نتيجة التحقق من توقيع واحد. [fp] بصمة الشهادة لو عرفناها. */
data class SigInfo(val status: SigStatus, val fp: String?, val keyId: String, val created: Long?) {
    fun toMap(): Map<String, Any?> = mapOf("status" to status.name, "fp" to fp, "keyId" to keyId, "created" to created)
}

data class MessageInfo(val encrypted: Boolean, val recipientKeyIds: List<String>, val passwordEncrypted: Boolean)

data class DecryptResult(val fileName: String?, val signatures: List<SigInfo>, val decryptedWith: String?)

/**
 * كل عمليات OpenPGP — على PGPainless (فوق Bouncy Castle).
 * الكلاس ده ملوش دعوة بالتخزين: بياخد مفاتيح وبيرجّع مفاتيح / بايتات.
 */
class Pgp {
    val api = PGPainless()

    // ---------------- قراية / كتابة ----------------

    /** يقرا مفتاح أو أكتر (armored أو binary). بيرمي `BAD_DATA` لو مفيش حاجة صالحة. */
    fun parse(bytes: ByteArray): List<OpenPGPCertificate> {
        val list = try {
            api.readKey().parseKeysOrCertificates(ByteArrayInputStream(bytes))
        } catch (e: IOException) {
            throw CoreError(Err.BAD_DATA)
        } catch (e: PGPException) {
            throw CoreError(Err.BAD_DATA)
        } catch (e: RuntimeException) {
            throw CoreError(Err.BAD_DATA)
        }
        if (list.isEmpty()) throw CoreError(Err.BAD_DATA)
        return list
    }

    fun parseKey(bytes: ByteArray): OpenPGPKey =
        parse(bytes).singleOrNull() as? OpenPGPKey ?: throw CoreError(Err.BAD_DATA)

    fun parseCert(bytes: ByteArray): OpenPGPCertificate =
        parse(bytes).singleOrNull() ?: throw CoreError(Err.BAD_DATA)

    fun encode(c: OpenPGPCertificate): ByteArray = c.encoded

    fun armor(c: OpenPGPCertificate): String = api.toAsciiArmor(c)

    fun armorAll(certs: List<OpenPGPCertificate>): String = certs.joinToString("\n") { armor(it) }

    fun publicPart(k: OpenPGPCertificate): OpenPGPCertificate = if (k is OpenPGPKey) k.toCertificate() else k

    fun fingerprint(c: OpenPGPCertificate): String = Bytes.hex(c.fingerprint)

    // ---------------- إنشاء ----------------

    fun generate(userId: String, passphrase: String?, algo: KeyAlgo, expires: Date?): OpenPGPKey {
        val b = when (algo) {
            KeyAlgo.CV25519 -> api.buildKey(OpenPGPKeyVersion.v4)
                .setPrimaryKey(KeySpec.getBuilder(KeyType.EDDSA_LEGACY(EdDSALegacyCurve._Ed25519), KeyFlag.CERTIFY_OTHER))
                .addSubkey(KeySpec.getBuilder(KeyType.EDDSA_LEGACY(EdDSALegacyCurve._Ed25519), KeyFlag.SIGN_DATA))
                .addSubkey(
                    KeySpec.getBuilder(
                        KeyType.XDH_LEGACY(XDHLegacySpec._X25519),
                        KeyFlag.ENCRYPT_COMMS,
                        KeyFlag.ENCRYPT_STORAGE,
                    ),
                )

            KeyAlgo.RSA4096 -> api.buildKey(OpenPGPKeyVersion.v4)
                .setPrimaryKey(KeySpec.getBuilder(KeyType.RSA(RsaLength._4096), KeyFlag.CERTIFY_OTHER))
                .addSubkey(KeySpec.getBuilder(KeyType.RSA(RsaLength._4096), KeyFlag.SIGN_DATA))
                .addSubkey(
                    KeySpec.getBuilder(KeyType.RSA(RsaLength._4096), KeyFlag.ENCRYPT_COMMS, KeyFlag.ENCRYPT_STORAGE),
                )

            KeyAlgo.V6 -> api.buildKey(OpenPGPKeyVersion.v6)
                .setPrimaryKey(KeySpec.getBuilder(KeyType.Ed25519(), KeyFlag.CERTIFY_OTHER))
                .addSubkey(KeySpec.getBuilder(KeyType.Ed25519(), KeyFlag.SIGN_DATA))
                .addSubkey(KeySpec.getBuilder(KeyType.X25519(), KeyFlag.ENCRYPT_COMMS, KeyFlag.ENCRYPT_STORAGE))
        }
        // مفاتيح v4 بتعلن إنها بتفهم SEIPDv1 بس (زي مفاتيح gpg / كيلوباترا): لو أعلنّا SEIPDv2 هنا،
        // الناس اللي بيستخدموا برامج حديثة هيبعتوا رسايل gpg مش هيعرف يفكها لو المفتاح اتنقل للكمبيوتر.
        if (algo != KeyAlgo.V6) b.withPreferences(V4_SUITE)
        b.addUserId(userId)
        b.setExpirationDate(expires)
        if (!passphrase.isNullOrEmpty()) b.setPassphrase(Passphrase.fromPassword(passphrase))
        return b.build()
    }

    /** شهادة إلغاء جاهزة (armored): لو المفتاح اتسرق أو ضاع، بتنشرها فالناس تعرف إنه ملغي. */
    fun revocationCertificate(key: OpenPGPKey, passphrase: String?): String = guard {
        val protector = protector(passphrase)
        val editor = api.modify(key, editTime(key))
        val attrs = RevocationAttributes.createKeyRevocation()
            .withReason(RevocationAttributes.Reason.NO_REASON)
            .withoutDescription()
        val cert = if (key.primaryKey.version == 6) {
            editor.createMinimalRevocationCertificate(protector, attrs)
        } else {
            val rev = editor.createRevocation(protector, attrs)
            KeyRingUtils.injectCertification(key.toCertificate().pgpPublicKeyRing, rev.signature)
                .toOpenPGPCertificate(api.implementation)
        }
        armor(cert)
    }

    // ---------------- كلمات سر المفاتيح ----------------

    fun isProtected(key: OpenPGPKey): Boolean = key.pgpSecretKeyRing.secretKeys.asSequence().any { it.isEncrypted() }

    fun checkPassphrase(key: OpenPGPKey, passphrase: String?): Boolean {
        val pass = passphrase(passphrase)
        return try {
            for (sk in key.pgpSecretKeyRing.secretKeys) {
                if (sk.isEncrypted()) sk.unlock(pass, api.algorithmPolicy)
            }
            true
        } catch (e: PGPException) {
            false
        } catch (e: RuntimeException) {
            false
        }
    }

    fun changePassphrase(key: OpenPGPKey, old: String?, new: String?): OpenPGPKey = guard {
        if (!checkPassphrase(key, old)) throw CoreError(Err.WRONG_PASSWORD)
        val editor = api.modify(key, editTime(key)).changePassphraseFromOldPassphrase(passphrase(old)).withSecureDefaultSettings()
        if (new.isNullOrEmpty()) editor.toNoPassphrase().done() else editor.toNewPassphrase(passphrase(new)).done()
    }

    // ---------------- تعديل المفاتيح ----------------

    fun setExpiry(key: OpenPGPKey, passphrase: String?, expires: Date?): OpenPGPKey = guard {
        unlockOrThrow(key, passphrase)
        api.modify(key, editTime(key)).setExpirationDate(expires, protector(passphrase)).done()
    }

    fun addUserId(key: OpenPGPKey, passphrase: String?, userId: String): OpenPGPKey = guard {
        unlockOrThrow(key, passphrase)
        api.modify(key, editTime(key)).addUserId(userId, protector(passphrase)).done()
    }

    fun revoke(key: OpenPGPKey, passphrase: String?, reason: RevocationAttributes.Reason, description: String): OpenPGPKey =
        guard {
            unlockOrThrow(key, passphrase)
            val attrs = RevocationAttributes.createKeyRevocation().withReason(reason).withDescription(description)
            api.modify(key, editTime(key)).revoke(protector(passphrase), attrs).done()
        }

    /** أوقّع على هويات شهادة حد تاني بمفتاحي (يعني "أنا اتأكدت إن المفتاح ده بتاعه"). */
    fun certify(myKey: OpenPGPKey, passphrase: String?, cert: OpenPGPCertificate): OpenPGPCertificate = guard {
        unlockOrThrow(myKey, passphrase)
        val uids = cert.getValidUserIds(Date()).map { it.userId }
        if (uids.isEmpty()) throw CoreError(Err.INVALID)
        var current = cert
        for (uid in uids) {
            current = api.generateCertification()
                .certifyUserId(uid, current)
                .withKey(myKey, protector(passphrase))
                .build()
                .certifiedCertificate
        }
        current
    }

    /** يدمج نسخة أحدث من نفس الشهادة (صلاحية جديدة، إلغاء، هويات...). */
    fun merge(base: OpenPGPCertificate, update: OpenPGPCertificate): OpenPGPCertificate = guard {
        if (!Bytes.equal(base.fingerprint, update.fingerprint)) throw CoreError(Err.INVALID)
        api.mergeCertificate(publicPart(base), publicPart(update))
    }

    /** يدمج تحديثات عامة في مفتاح سري (الجزء السري بيفضل زي ما هو). */
    fun mergeIntoKey(key: OpenPGPKey, update: OpenPGPCertificate): OpenPGPKey = guard {
        val merged = merge(key.toCertificate(), update)
        api.toKey(PGPSecretKeyRing.replacePublicKeys(key.pgpSecretKeyRing, merged.pgpPublicKeyRing))
    }

    // ---------------- معلومات ----------------

    fun summary(c: OpenPGPCertificate, now: Date = Date()): Map<String, Any?> {
        val info = api.inspect(c, now)
        val expires = safe { info.primaryKeyExpirationDate }
        val revoked = !info.revocationState.isNotRevoked()
        val primaryUid = info.primaryUserId ?: info.userIds.firstOrNull()
        val subkeys = c.keys.map { k ->
            val pk = k.pgpPublicKey
            // مفتاح فرعي ملغي أو ربطه بايظ بيرمي AssertionError جوه المكتبة
            val subExp = if (k.isPrimaryKey) expires else safe { info.getSubkeyExpirationDate(k.keyIdentifier) }
            mapOf(
                "fp" to Bytes.hex(pk.fingerprint),
                "algo" to algoName(pk.algorithm, pk.bitStrength),
                "created" to pk.creationTime.time,
                "expires" to subExp?.time,
                "primary" to k.isPrimaryKey,
                "flags" to (safe { info.getKeyFlagsOf(k.keyIdentifier).map { it.name } } ?: emptyList<String>()),
                "valid" to (safe { info.isKeyValidlyBound(k.keyIdentifier) } ?: false),
                "secret" to (c is OpenPGPKey && c.getSecretKey(k.keyIdentifier) != null),
            )
        }
        return mapOf(
            "fp" to fingerprint(c),
            "keyId" to Bytes.hex(c.fingerprint).let { if (c.primaryKey.version == 6) it.take(16) else it.takeLast(16) },
            "version" to c.primaryKey.version,
            "uids" to info.userIds,
            "validUids" to info.validUserIds,
            "primaryUid" to primaryUid,
            "algo" to algoName(c.primaryKey.pgpPublicKey.algorithm, c.primaryKey.pgpPublicKey.bitStrength),
            "created" to info.creationDate.time,
            "expires" to expires?.time,
            "expired" to (expires != null && expires.before(now)),
            "revoked" to revoked,
            "secret" to (c is OpenPGPKey),
            "protected" to (c is OpenPGPKey && isProtected(c)),
            "canEncrypt" to info.isUsableForEncryption,
            "canSign" to (if (c is OpenPGPKey) info.isUsableForSigning else info.isSigningCapable),
            "canCertify" to (c is OpenPGPKey && info.isUsableForThirdPartyCertification),
            "subkeys" to subkeys,
        )
    }

    // ---------------- تشفير / فك ----------------

    fun encrypt(
        input: InputStream,
        output: OutputStream,
        recipients: List<OpenPGPCertificate>,
        signer: OpenPGPKey?,
        signerPass: String?,
        armor: Boolean,
        fileName: String?,
    ) = guard {
        if (recipients.isEmpty()) throw CoreError(Err.INVALID)
        val enc = EncryptionOptions.get(api)
        for (r in recipients) {
            try {
                enc.addRecipient(publicPart(r))
            } catch (e: KeyException) {
                throw CoreError(Err.CANNOT_ENCRYPT, detail = fingerprint(r))
            } catch (e: IllegalArgumentException) {
                throw CoreError(Err.CANNOT_ENCRYPT, detail = fingerprint(r))
            }
        }
        val opts = if (signer != null) {
            ProducerOptions.signAndEncrypt(enc, signingOptions(signer, signerPass, DocumentSignatureType.BINARY_DOCUMENT, inline = true))
        } else {
            ProducerOptions.encrypt(enc)
        }
        opts.setAsciiArmor(armor)
        opts.setHideArmorHeaders(true)
        if (fileName != null) opts.setFileName(fileName)
        val stream = api.generateMessage().onOutputStream(output).withOptions(opts)
        input.copyTo(stream, BUFFER)
        stream.close()
    }

    /**
     * تشفير بكلمة سر (من غير مفاتيح). [modern] = RFC 9580: Argon2 + AES-256-OCB (للنسخ الاحتياطية).
     * غير كده: الصيغة القديمة اللي gpg بيفهمها.
     */
    fun encryptWithPassword(input: InputStream, output: OutputStream, password: String, armor: Boolean, modern: Boolean) =
        guard {
            if (password.isEmpty()) throw CoreError(Err.INVALID)
            val enc = EncryptionOptions.get(api)
            if (modern) {
                enc.addEncryptionMethod(
                    BcPBEKeyEncryptionMethodGenerator(password.toCharArray(), S2K.Argon2Params.memoryConstrainedParameters())
                        .setSecureRandom(SecureRandom()),
                )
                enc.overrideEncryptionMechanism(
                    MessageEncryptionMechanism.aead(SymmetricKeyAlgorithm.AES_256.algorithmId, AEADAlgorithm.OCB.algorithmId),
                )
            } else {
                enc.addMessagePassphrase(Passphrase.fromPassword(password))
            }
            val opts = ProducerOptions.encrypt(enc).setAsciiArmor(armor).setHideArmorHeaders(true)
            val stream = api.generateMessage().onOutputStream(output).withOptions(opts)
            input.copyTo(stream, BUFFER)
            stream.close()
        }

    /** بيبص على الرسالة من غير ما يفكها: متشفّرة لمين؟ */
    fun inspect(input: InputStream): MessageInfo = guard {
        val info = MessageInspector(api).determineEncryptionInfoForMessage(input)
        MessageInfo(
            info.isEncrypted,
            info.keyIdentifiers.map { java.lang.Long.toUnsignedString(it.keyId, 16).padStart(16, '0').uppercase() },
            info.isPassphraseEncrypted,
        )
    }

    /**
     * فك التشفير. ⚠️ الناتج بيتكتب أول بأول، والتحقق من السلامة بيخلص في الآخر: لو رمى `INTEGRITY`
     * لازم اللي نادى يمسح الناتج كله (شوف [Api]).
     */
    fun decrypt(
        input: InputStream,
        output: OutputStream,
        keys: List<Pair<OpenPGPKey, String?>>,
        password: String?,
        verifyWith: List<OpenPGPCertificate>,
    ): DecryptResult = guard {
        val opts = ConsumerOptions.get(api)
        for ((k, p) in keys) opts.addDecryptionKey(k, protector(p))
        if (!password.isNullOrEmpty()) opts.addMessagePassphrase(Passphrase.fromPassword(password))
        opts.addVerificationCerts(verifyWith.map { publicPart(it) })
        val stream = try {
            api.processMessage().onInputStream(input).withOptions(opts)
        } catch (e: MissingDecryptionMethodException) {
            throw CoreError(if (password.isNullOrEmpty()) Err.NO_KEY else Err.WRONG_PASSWORD)
        }
        stream.copyTo(output, BUFFER)
        stream.close()
        val md = stream.metadata
        if (!md.isEncrypted) throw CoreError(Err.BAD_DATA, detail = "not encrypted")
        DecryptResult(
            md.filename?.takeIf { it.isNotEmpty() && it != "_CONSOLE" },
            sigInfos(md.verifiedInlineSignatures, md.rejectedInlineSignatures, verifyWith),
            md.decryptionKey?.certificateFingerprint?.toString()?.uppercase(),
        )
    }

    // ---------------- توقيع / تحقق ----------------

    fun sign(input: InputStream, output: OutputStream, key: OpenPGPKey, passphrase: String?, mode: SignMode, armor: Boolean) =
        guard {
            when (mode) {
                SignMode.DETACHED -> {
                    val so = signingOptions(key, passphrase, DocumentSignatureType.BINARY_DOCUMENT, inline = false)
                    val stream = api.generateMessage().discardOutput().withOptions(
                        ProducerOptions.sign(so).setAsciiArmor(armor)
                            .overrideCompressionAlgorithm(CompressionAlgorithm.UNCOMPRESSED),
                    )
                    input.copyTo(stream, BUFFER)
                    stream.close()
                    val sigs = stream.result.detachedDocumentSignatures
                    val out: OutputStream = if (armor) ArmoredOutputStream.builder().clearHeaders().build(output) else output
                    sigs.forEach { it.signature.encode(out) }
                    if (armor) out.close()
                }

                SignMode.CLEAR -> {
                    val so = signingOptions(key, passphrase, DocumentSignatureType.CANONICAL_TEXT_DOCUMENT, inline = false)
                    val opts = ProducerOptions.sign(so).apply {
                        setCleartextSigned()
                        setAsciiArmor(true)
                        setHideArmorHeaders(true)
                        setEncoding(StreamEncoding.TEXT)
                        applyCRLFEncoding()
                        overrideCompressionAlgorithm(CompressionAlgorithm.UNCOMPRESSED)
                    }
                    val stream = api.generateMessage().onOutputStream(output).withOptions(opts)
                    input.copyTo(stream, BUFFER)
                    stream.close()
                }

                SignMode.INLINE -> {
                    val so = signingOptions(key, passphrase, DocumentSignatureType.BINARY_DOCUMENT, inline = true)
                    val opts = ProducerOptions.sign(so).setAsciiArmor(armor).setHideArmorHeaders(true)
                    val stream = api.generateMessage().onOutputStream(output).withOptions(opts)
                    input.copyTo(stream, BUFFER)
                    stream.close()
                }
            }
        }

    /**
     * التحقق. [signature] = توقيع منفصل (.sig/.asc) للملف [input]؛ من غيره الرسالة نفسها موقّعة
     * (cleartext أو inline) والنص الأصلي بيتكتب في [output].
     */
    fun verify(
        input: InputStream,
        output: OutputStream?,
        signature: InputStream?,
        certs: List<OpenPGPCertificate>,
    ): List<SigInfo> = guard {
        val opts = ConsumerOptions.get(api)
        opts.addVerificationCerts(certs.map { publicPart(it) })
        if (signature != null) {
            opts.forceNonOpenPgpData()
            opts.addVerificationOfDetachedSignatures(signature)
        }
        val stream = try {
            api.processMessage().onInputStream(input).withOptions(opts)
        } catch (e: MissingDecryptionMethodException) {
            throw CoreError(Err.INVALID, detail = "encrypted")
        }
        if (output != null) stream.copyTo(output, BUFFER) else stream.copyTo(NullOut, BUFFER)
        stream.close()
        val md = stream.metadata
        val res = if (signature != null || md.isUsingCleartextSignatureFramework) {
            sigInfos(md.verifiedDetachedSignatures, md.rejectedDetachedSignatures, certs)
        } else {
            sigInfos(md.verifiedInlineSignatures, md.rejectedInlineSignatures, certs)
        }
        if (res.isEmpty()) throw CoreError(Err.BAD_DATA, detail = "no signature")
        res
    }

    // ---------------- داخلي ----------------

    private fun signingOptions(key: OpenPGPKey, passphrase: String?, type: DocumentSignatureType, inline: Boolean): SigningOptions {
        val info = api.inspect(key)
        if (!info.isUsableForSigning) throw CoreError(Err.CANNOT_SIGN)
        unlockOrThrow(key, passphrase)
        val so = SigningOptions.get(api)
        try {
            if (inline) so.addInlineSignature(protector(passphrase), key, type)
            else so.addDetachedSignature(protector(passphrase), key, type)
        } catch (e: KeyException) {
            throw CoreError(Err.CANNOT_SIGN)
        }
        return so
    }

    private fun sigInfos(
        good: List<SignatureVerification>,
        bad: List<SignatureVerification.Failure>,
        known: List<OpenPGPCertificate>,
    ): List<SigInfo> {
        val out = mutableListOf<SigInfo>()
        for (v in good) {
            out += SigInfo(
                SigStatus.GOOD,
                v.signingKey.certificateFingerprint.toString().uppercase(),
                keyIdOf(v.signature),
                v.signature.creationTime?.time,
            )
        }
        for (f in bad) {
            val keyId = keyIdOf(f.signature)
            val cert = known.firstOrNull { c -> c.keys.any { Bytes.hex(it.pgpPublicKey.fingerprint).endsWith(keyId) } }
            out += SigInfo(
                if (cert == null) SigStatus.UNKNOWN_KEY else SigStatus.BAD,
                cert?.let { fingerprint(it) },
                keyId,
                f.signature.creationTime?.time,
            )
        }
        return out
    }

    private fun keyIdOf(sig: PGPSignature): String {
        val fp = sig.hashedSubPackets?.issuerFingerprint?.fingerprint ?: sig.unhashedSubPackets?.issuerFingerprint?.fingerprint
        if (fp != null) {
            val hex = Bytes.hex(fp)
            return if (fp.size == 32) hex.take(16) else hex.takeLast(16)
        }
        return java.lang.Long.toUnsignedString(sig.keyID, 16).padStart(16, '0').uppercase()
    }

    /**
     * وقت التوقيعات الجديدة: التوقيعات دقتها ثانية، فلو اتعمل تعديلين في نفس الثانية الجديد
     * ممكن ميتختارش، فلو احنا في نفس ثانية آخر تعديل بنستنى للثانية اللي بعدها.
     */
    private fun editTime(key: OpenPGPKey): Date {
        val last = key.lastModificationDate?.time ?: 0L
        var now = System.currentTimeMillis()
        if (now / 1000 <= last / 1000) {
            Thread.sleep(1000 - now % 1000 + 10)
            now = System.currentTimeMillis()
        }
        return Date(now)
    }

    private fun unlockOrThrow(key: OpenPGPKey, passphrase: String?) {
        if (!checkPassphrase(key, passphrase)) throw CoreError(Err.WRONG_PASSWORD)
    }

    private fun passphrase(p: String?) = if (p.isNullOrEmpty()) Passphrase.emptyPassphrase() else Passphrase.fromPassword(p)

    private fun protector(p: String?): SecretKeyRingProtector =
        if (p.isNullOrEmpty()) SecretKeyRingProtector.unprotectedKeys() else SecretKeyRingProtector.unlockAnyKeyWith(passphrase(p))

    /** يحوّل استثناءات المكتبة لأكواد [Err] بس. */
    private inline fun <T> guard(block: () -> T): T = try {
        block()
    } catch (e: CoreError) {
        throw e
    } catch (e: WrongPassphraseException) {
        throw CoreError(Err.WRONG_PASSWORD)
    } catch (e: MissingPassphraseException) {
        throw CoreError(Err.WRONG_PASSWORD)
    } catch (e: ModificationDetectionException) {
        throw CoreError(Err.INTEGRITY)
    } catch (e: MissingDecryptionMethodException) {
        throw CoreError(Err.NO_KEY)
    } catch (e: MalformedOpenPgpMessageException) {
        throw CoreError(Err.BAD_DATA)
    } catch (e: KeyException) {
        throw CoreError(Err.CANNOT_ENCRYPT)
    } catch (e: PGPException) {
        throw CoreError(if (isIntegrity(e)) Err.INTEGRITY else Err.BAD_DATA)
    } catch (e: IOException) {
        throw CoreError(if (isIntegrity(e)) Err.INTEGRITY else Err.BAD_DATA)
    } catch (e: IllegalArgumentException) {
        throw CoreError(Err.BAD_DATA)
    } catch (e: IllegalStateException) {
        throw CoreError(Err.BAD_DATA)
    } catch (e: AssertionError) {
        throw CoreError(Err.BAD_DATA)
    }

    private inline fun <T> safe(block: () -> T): T? = try {
        block()
    } catch (e: Exception) {
        null
    } catch (e: AssertionError) {
        null
    }

    private fun isIntegrity(e: Throwable): Boolean {
        var t: Throwable? = e
        while (t != null) {
            val m = t.message?.lowercase() ?: ""
            if (t is ModificationDetectionException || "integrity" in m || "mdc" in m || "aead" in m || "tag mismatch" in m ||
                "mac check" in m
            ) {
                return true
            }
            t = t.cause
        }
        return false
    }

    private object NullOut : OutputStream() {
        override fun write(b: Int) {}
        override fun write(b: ByteArray, off: Int, len: Int) {}
    }

    companion object {
        const val BUFFER = 64 * 1024

        /** تفضيلات مفاتيح v4: نفس الافتراضي بس من غير AEAD / SEIPDv2. */
        private val V4_SUITE = AlgorithmSuite.defaultAlgorithmSuite.modify()
            .overrideFeatures(Feature.MODIFICATION_DETECTION)
            .overrideAeadAlgorithms(null)
            .build()

        fun algoName(algo: Int, bits: Int): String = when (algo) {
            1, 2, 3 -> "RSA-$bits"
            16, 20 -> "ElGamal-$bits"
            17 -> "DSA-$bits"
            18 -> ecName("ECDH", bits)
            19 -> ecName("ECDSA", bits)
            22 -> if (bits >= 448) "Ed448" else "Ed25519"
            25 -> "X25519"
            26 -> "X448"
            27 -> "Ed25519"
            28 -> "Ed448"
            else -> "#$algo"
        }

        private fun ecName(prefix: String, bits: Int) = when (bits) {
            255 -> "Cv25519"
            256 -> "$prefix P-256"
            384 -> "$prefix P-384"
            521 -> "$prefix P-521"
            else -> "$prefix-$bits"
        }

        /** فك في الذاكرة (للنصوص) مع حد أقصى للحجم عشان رسالة مضغوطة متفجّرش الذاكرة. */
        fun limited(limit: Long) = LimitedBuffer(limit)
    }
}

/** ByteArrayOutputStream بحد أقصى — بيرمي `TOO_LARGE` لو عدّاه. */
class LimitedBuffer(private val limit: Long) : ByteArrayOutputStream() {
    override fun write(b: Int) {
        if (count + 1 > limit) throw CoreError(Err.TOO_LARGE)
        super.write(b)
    }

    override fun write(b: ByteArray, off: Int, len: Int) {
        if (count.toLong() + len > limit) throw CoreError(Err.TOO_LARGE)
        super.write(b, off, len)
    }

    /** يمسح المحتوى من الذاكرة. */
    fun wipe() {
        buf.fill(0)
        reset()
    }
}
