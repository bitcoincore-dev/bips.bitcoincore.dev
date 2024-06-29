.PHONY:web scripts
default:
	cargo b
	$(MAKE) web
web: scripts
	cd web && zola serve
scripts:
	. ./scripts/bips.sh
	. ./scripts/mints.sh
	. ./scripts/static.sh
	. ./scripts/generate.sh
	. ./scripts/tailwind.sh
	. ./scripts/install-pagefind.sh
	. ./scripts/install-zola.sh
