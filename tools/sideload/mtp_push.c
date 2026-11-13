// mtp-push: copy one file into GARMIN/Apps on the first MTP device (a Garmin
// watch), replacing any file with the same name there. Touches nothing else.
//
// Usage: mtp-push <local file> <remote file name>
// Exit codes: 0 copied and confirmed, 1 copy not confirmed, 2 no device or
// GARMIN/Apps, or old copies could not be removed.
//
// The FR265 is quirky over MTP, so this tool:
// - names the storage explicitly (the watch rejects storage id 0);
// - uses a cached session: an uncached one made the FR265 store every sent
//   file twice;
// - never trusts a listing made in the same session as a change, so every
//   check opens a fresh session;
// - ignores the return code of a delete (the watch can report an error for a
//   delete that worked) and checks the result instead.
#include <libmtp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>

typedef struct {
    LIBMTP_mtpdevice_t *dev;
    uint32_t storage;
    uint32_t apps;
} Session;

// Returns the id of the folder named `name` among the siblings `f` whose
// parent is `parent` (ANY_PARENT matches every parent), or 0. `child`
// (optional) gets that folder's children.
#define ANY_PARENT 0xFFFFFFFFu

static uint32_t find_folder(LIBMTP_folder_t *f, uint32_t parent, const char *name,
                            LIBMTP_folder_t **child) {
    for (; f != NULL; f = f->sibling) {
        if ((parent == ANY_PARENT || f->parent_id == parent) && strcasecmp(f->name, name) == 0) {
            if (child != NULL) *child = f->child;
            return f->folder_id;
        }
    }
    return 0;
}

// Opens a fresh session and finds GARMIN/Apps. Returns 0 on success.
static int open_session(Session *s) {
    LIBMTP_raw_device_t *raw = NULL;
    int count = 0;
    memset(s, 0, sizeof(*s));
    if (LIBMTP_Detect_Raw_Devices(&raw, &count) != LIBMTP_ERROR_NONE || count < 1) {
        fprintf(stderr, "no MTP device found (is the watch plugged in? quit OpenMTP and Garmin Express)\n");
        return -1;
    }
    s->dev = LIBMTP_Open_Raw_Device(&raw[0]);
    free(raw);
    if (s->dev == NULL) {
        fprintf(stderr, "could not open the device; unplug and replug it\n");
        return -1;
    }
    if (LIBMTP_Get_Storage(s->dev, LIBMTP_STORAGE_SORTBY_NOTSORTED) != 0 || s->dev->storage == NULL) {
        fprintf(stderr, "could not read the device storage\n");
        return -1;
    }
    s->storage = s->dev->storage->id;
    LIBMTP_folder_t *root = LIBMTP_Get_Folder_List_For_Storage(s->dev, s->storage);
    LIBMTP_folder_t *inside = NULL;
    uint32_t garmin = find_folder(root, ANY_PARENT, "GARMIN", &inside);
    s->apps = garmin ? find_folder(inside, garmin, "Apps", NULL) : 0;
    LIBMTP_destroy_folder_t(root);
    if (s->apps == 0) {
        fprintf(stderr, "GARMIN/Apps not found on the device\n");
        return -1;
    }
    return 0;
}

static void close_session(Session *s) {
    if (s->dev != NULL) LIBMTP_Release_Device(s->dev);
    s->dev = NULL;
}

// Counts the files named `name` in GARMIN/Apps, deleting each one when `del`
// is set. `size` (optional) gets the size of the last match.
static int scan(Session *s, const char *name, int del, uint64_t *size) {
    int n = 0;
    LIBMTP_file_t *f = LIBMTP_Get_Filelisting_With_Callback(s->dev, NULL, NULL);
    while (f != NULL) {
        LIBMTP_file_t *next = f->next;
        if (f->storage_id == s->storage && f->parent_id == s->apps
                && f->filetype != LIBMTP_FILETYPE_FOLDER && strcasecmp(f->filename, name) == 0) {
            n++;
            if (size != NULL) *size = f->filesize;
            if (del) LIBMTP_Delete_Object(s->dev, f->item_id);
        }
        LIBMTP_destroy_file_t(f);
        f = next;
    }
    LIBMTP_Clear_Errorstack(s->dev);
    return n;
}

// Opens a fresh session and counts the copies of `name`.
static int count_fresh(const char *name, uint64_t *size) {
    Session s;
    int n = open_session(&s) == 0 ? scan(&s, name, 0, size) : -1;
    close_session(&s);
    return n;
}

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "usage: mtp-push <local file> <remote file name>\n");
        return 2;
    }
    const char *local = argv[1], *remote = argv[2];
    struct stat st;
    if (stat(local, &st) != 0) { perror(local); return 2; }
    LIBMTP_Init();

    // 1. Remove old copies, then confirm in a fresh session.
    Session s;
    if (open_session(&s) != 0) { close_session(&s); return 2; }
    int removed = scan(&s, remote, 1, NULL);
    close_session(&s);
    if (count_fresh(remote, NULL) != 0) {
        fprintf(stderr, "could not remove the existing %s\n", remote);
        return 2;
    }
    if (removed > 0) printf("removed the existing %s\n", remote);

    // 2. Send the file.
    if (open_session(&s) != 0) { close_session(&s); return 2; }
    LIBMTP_file_t *file = LIBMTP_new_file_t();
    file->filename = strdup(remote);
    file->filesize = (uint64_t)st.st_size;
    file->filetype = LIBMTP_FILETYPE_UNKNOWN;
    file->parent_id = s.apps;
    file->storage_id = s.storage;
    int sent = LIBMTP_Send_File_From_File(s.dev, local, file, NULL, NULL);
    if (sent != 0) LIBMTP_Dump_Errorstack(s.dev);
    LIBMTP_destroy_file_t(file);
    close_session(&s);

    // 3. Confirm in a fresh session: exactly one copy, full size.
    uint64_t size = 0;
    int copies = count_fresh(remote, &size);
    if (copies == 1 && size == (uint64_t)st.st_size) {
        printf("copied to GARMIN/Apps/%s (%llu bytes)\n", remote, (unsigned long long)size);
        return 0;
    }
    fprintf(stderr, "copy not confirmed: send returned %d, %d copies on the watch\n", sent, copies);
    return 1;
}
