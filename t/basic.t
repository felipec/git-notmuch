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

nm_check() {
	ruby <<-EOF > actual &&
	require 'notmuch'
	db = Notmuch::Database.new('$HOME/mail')
	puts db.find_message('$1').tags.to_a.join(' ')
	EOF
	echo "$2" > expected &&
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

test_expect_success 'push' '
	notmuch tag -unread "id:1258506353-20352-1-git-send-email-stewart@flamingspork.com" &&
	(
	cd mail.git &&
	git pull origin &&
	check . "1258506353-20352-1-git-send-email-stewart@flamingspork.com" "" &&
	git checkout @~ -- . &&
	git commit -m "go back" &&
	check . "1258506353-20352-1-git-send-email-stewart@flamingspork.com" "unread" &&
	git push --verbose
	) &&
	nm_check "1258506353-20352-1-git-send-email-stewart@flamingspork.com" "unread"
'

test_expect_success 'up to date' '
	(
	cd mail.git &&
	git rev-parse origin/master > expected &&
	git fetch origin &&
	git rev-parse origin/master > actual &&
	test_cmp actual expected &&
	git rev-parse origin/master > expected &&
	git push --verbose &&
	git rev-parse origin/master > actual &&
	test_cmp actual expected
	)
'

test_expect_success 'encoding' '
	id="/x//x///x////xx/@bar.com" &&

	cat > "$HOME/mail/new/enc" <<-EOF &&
	Date: Tue, 28 Mar 2023 20:52:09 -0600
	From: Foo Bar <foo@bar.com>
	To: Nobody <me@nobody.com>
	Subject: Weird message-id
	Message-ID: <$id>
	MIME-Version: 1.0

	Content
	EOF

	notmuch new &&
	(
	cd mail.git &&
	git pull &&
	echo encoding >> "%47x%47/x%47%47/x%47%47%47/xx/@bar.com/tags" &&
	git commit -a -m "add encoding" &&
	git push
	) &&
	nm_check "$id" "encoding inbox unread"
'

test_done
