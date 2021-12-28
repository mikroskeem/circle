//usr/bin/env cc -D_LD="\"${LD:-ld}\"" -D_LDSO="\"${LDSO:-}\"" -shared -fPIC -ldl -o redirect.so redirect.c; exit
#define _GNU_SOURCE

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <dlfcn.h>
#include <errno.h>
#include <limits.h>

#define PREFIX "[ld redirect]"
#ifndef _LD
#	define _LD "@ld@"
#endif
#ifndef _LDSO
#	define _LDSO "@ldso@"
#endif

static int (*orig_system)(const char *command) = NULL;

static inline void *get_sym(const char *name) {
	void *sym = NULL;
	if ((sym = dlsym(RTLD_NEXT, name)) == NULL) {
		fprintf(stderr, PREFIX " ERROR: failed to dlsym '%s' symbol\n", name);
		_exit(1);
	}
	return sym;
}

static void __attribute__((constructor)) init();
static void init() {
	orig_system = get_sym("system");
}

// idk where i copy pasted this, don't punch me
char* replace_word(const char* s, const char* old, const char* new) {
	char *result;
	int i, cnt = 0;
	int new_len = strlen(new);
	int old_len = strlen(old);

	// Counting the number of times old word
	// occur in the string
	for (i = 0; s[i] != '\0'; i++) {
		if (strstr(&s[i], old) == &s[i]) {
			cnt++;

			// Jumping to index after the old word.
			i += old_len - 1;
		}
	}

	// Making new string of enough length
	result = (char *) malloc(i + cnt * (new_len - old_len) + 1);

	i = 0;
	while (*s) {
		// compare the substring with the result
		if (strstr(s, old) == s) {
			strcpy(&result[i], new);
			i += new_len;
			s += old_len;
		} else {
			result[i++] = *s++;
		}
	}

	result[i] = '\0';
	return result;
}

/* EXPORT */ int system(const char *command) {
#ifndef NDEBUG
	fprintf(stderr, PREFIX " command: '%s'\n", command);
#endif

	const char *usrbinld = "/usr/bin/ld";
	if (strncmp(command, usrbinld, strlen(usrbinld)) != 0) {
		goto end;
	}

	int r = 0;
	// circle 145 hardcodes /usr/bin/ld and ld.so path
	char *new_command = replace_word(command, usrbinld, _LD);
	char *new_command2 = replace_word(new_command, "/lib64/ld-linux-x86-64.so.2", _LDSO);

#ifndef NDEBUG
	fprintf(stderr, PREFIX " new command: '%s'\n", new_command2);
#endif
	r = orig_system(new_command2);

	free(new_command);
	free(new_command2);

	return r;
end:
	return orig_system(command);
}
