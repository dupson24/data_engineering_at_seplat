# ── MOUNT ────────────────────────────────────────────────────────────────────
def ensure_mount():
    existing = [m.mountPoint for m in dbutils.fs.mounts()]
    if MOUNT not in existing:
        dbutils.fs.mount(
            source="wasbs://seplat-security-phishme@seplatedwstorage.blob.core.windows.net",
            mount_point=MOUNT,
            extra_configs={
                "fs.azure.account.key.seplatedwstorage.blob.core.windows.net":
                    dbutils.secrets.get(scope="CorpAvailScope", key="CorpAvailkeys")
            }
        )
        print(f"✅ Mounted at {MOUNT}")
    else:
        print(f"✅ Already mounted at {MOUNT}")