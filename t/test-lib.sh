. "${SHARNESS_TEST_SRCDIR-/usr/share/sharness}"/sharness.sh || exit 1

touch "$HOME/.notmuch-config"

add_email_corpus() {
	rm -rf "$HOME/mail"
	cp -a "$SHARNESS_TEST_DIRECTORY"/corpora/default "$HOME/mail"
	notmuch new --quiet
}

test_cmp() {
	diff -u "$@"
}
