#!/bin/sh
# Copyright (c) 2023 Felipe Contreras

test_description='Basic tests'

. ./test-lib.sh

# shellcheck disable=SC2086

check() {
	printf "%s\n" $3 > expected &&
	git -C "$1" cat-file -p @:"$2/tags" > actual &&
	test_cmp expected actual
}

test_expect_success 'setup' '
	add_email_corpus
'

test_expect_success 'cloning' '
	git clone "nm::$HOME/mail" mail.git &&
	check mail.git "1258506353-20352-1-git-send-email-stewart@flamingspork.com" "inbox unread"
'

test_expect_success 'pull' '
	notmuch tag -inbox tag:inbox &&
	git -C mail.git pull origin &&
	check mail.git "1258506353-20352-1-git-send-email-stewart@flamingspork.com" "unread"
'

test_done
