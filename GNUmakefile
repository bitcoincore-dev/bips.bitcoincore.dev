.PHONY:web scripts
web: scripts
	cd web && zola serve
scripts:
	. ./scripts/bips.sh
	. ./scripts/static.sh
	. ./scripts/generate.sh
	. ./scripts/tailwind.sh
	. ./scripts/install-pagefind.sh
	. ./scripts/install-zola.sh
