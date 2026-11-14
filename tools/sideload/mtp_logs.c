// mtp-logs: the files in GARMIN/Apps/LOGS on the first MTP device (a Garmin
// watch): the app logs (<APP>.TXT) and profiler logs (<APP>.PRF). Run it
// through scripts/watch-logs.sh. Same FR265 workarounds as mtp_push.c:
// explicit storage id, a fresh session after every change.
//
//   mtp-logs list                      name and size of every file
//   mtp-logs put <local file> <name>   create or replace <name>
//   mtp-logs get <name> <local file>   copy <name> from the watch
//   mtp-logs del <name>                delete <name>, confirmed in a new session
//
// Exit codes: 0 done, 1 the file was not found or not copied, 2 no device,
// no GARMIN/Apps/LOGS, or bad arguments.
#include <libmtp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>

static LIBMTP_mtpdevice_t *dev; static uint32_t storage, logs;

static uint32_t find_folder(LIBMTP_folder_t *f, uint32_t parent, const char *name, LIBMTP_folder_t **child) {
    for (; f; f = f->sibling)
        if ((parent == 0xFFFFFFFFu || f->parent_id == parent) && strcasecmp(f->name, name) == 0) {
            if (child) *child = f->child; return f->folder_id; }
    return 0;
}
static int open_session(void) {
    LIBMTP_raw_device_t *raw = NULL; int count = 0;
    if (LIBMTP_Detect_Raw_Devices(&raw, &count) != LIBMTP_ERROR_NONE || count < 1) { fprintf(stderr, "no MTP device\n"); return -1; }
    dev = LIBMTP_Open_Raw_Device(&raw[0]); free(raw);
    if (!dev || LIBMTP_Get_Storage(dev, LIBMTP_STORAGE_SORTBY_NOTSORTED) != 0 || !dev->storage) { fprintf(stderr, "cannot open device\n"); return -1; }
    storage = dev->storage->id;
    LIBMTP_folder_t *root = LIBMTP_Get_Folder_List_For_Storage(dev, storage), *g = NULL, *a = NULL;
    uint32_t garmin = find_folder(root, 0xFFFFFFFFu, "GARMIN", &g);
    uint32_t apps = garmin ? find_folder(g, garmin, "Apps", &a) : 0;
    logs = apps ? find_folder(a, apps, "LOGS", NULL) : 0;
    LIBMTP_destroy_folder_t(root);
    if (!logs) { fprintf(stderr, "GARMIN/Apps/LOGS not found\n"); return -1; }
    return 0;
}
// Walks the files in LOGS: lists them all (name NULL), or for the files named
// `name` deletes them (`del`) or copies them to `get_to`. Returns the matches.
static int each(const char *name, int del, const char *get_to) {
    int n = 0;
    LIBMTP_file_t *f = LIBMTP_Get_Filelisting_With_Callback(dev, NULL, NULL);
    while (f) {
        LIBMTP_file_t *next = f->next;
        if (f->storage_id == storage && f->parent_id == logs && f->filetype != LIBMTP_FILETYPE_FOLDER
                && (!name || strcasecmp(f->filename, name) == 0)) {
            n++;
            if (!name) printf("%s\t%llu\n", f->filename, (unsigned long long)f->filesize);
            if (del) LIBMTP_Delete_Object(dev, f->item_id);
            if (get_to && LIBMTP_Get_File_To_File(dev, f->item_id, get_to, NULL, NULL) != 0) { LIBMTP_Dump_Errorstack(dev); n = -1; }
        }
        LIBMTP_destroy_file_t(f); f = next;
    }
    LIBMTP_Clear_Errorstack(dev);
    return n;
}
int main(int argc, char **argv) {
    LIBMTP_Init();
    if (argc < 2 || open_session() != 0) return 2;
    int rc = 0;
    if (!strcmp(argv[1], "list")) each(NULL, 0, NULL);
    else if (!strcmp(argv[1], "get") && argc == 4) rc = each(argv[2], 0, argv[3]) == 1 ? 0 : 1;
    else if (!strcmp(argv[1], "del") && argc == 3) {
        int found = each(argv[2], 1, NULL);
        LIBMTP_Release_Device(dev); if (open_session() != 0) return 2;
        rc = found < 1 || each(argv[2], 0, NULL) != 0;
        if (!rc) printf("deleted GARMIN/Apps/LOGS/%s\n", argv[2]);
    }
    else if (!strcmp(argv[1], "put") && argc == 4) {
        struct stat st; if (stat(argv[2], &st)) { perror(argv[2]); return 2; }
        each(argv[3], 1, NULL);
        LIBMTP_Release_Device(dev); if (open_session() != 0) return 2;
        LIBMTP_file_t *file = LIBMTP_new_file_t();
        file->filename = strdup(argv[3]); file->filesize = (uint64_t)st.st_size;
        file->filetype = LIBMTP_FILETYPE_UNKNOWN; file->parent_id = logs; file->storage_id = storage;
        rc = LIBMTP_Send_File_From_File(dev, argv[2], file, NULL, NULL) != 0;
        if (rc) LIBMTP_Dump_Errorstack(dev);
        LIBMTP_destroy_file_t(file);
    } else { fprintf(stderr, "usage: mtp-logs list | put <local> <name> | get <name> <local> | del <name>\n"); rc = 2; }
    LIBMTP_Release_Device(dev);
    return rc;
}
