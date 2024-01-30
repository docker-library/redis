#!/usr/bin/env bash
set -Eeuo pipefail

[ -f versions.json ] # run "versions.sh" first

jqt='.jq-template.awk'
if [ -n "${BASHBREW_SCRIPTS:-}" ]; then
	jqt="$BASHBREW_SCRIPTS/jq-template.awk"
elif [ "$BASH_SOURCE" -nt "$jqt" ]; then
	# https://github.com/docker-library/bashbrew/blob/master/scripts/jq-template.awk
	wget -qO "$jqt" 'https://github.com/docker-library/bashbrew/raw/9f6a35772ac863a0241f147c820354e4008edf38/scripts/jq-template.awk'
fi

jqf='.template-helper-functions.jq'
if [ -n "${BASHBREW_SCRIPTS:-}" ]; then
	jqf="$BASHBREW_SCRIPTS/template-helper-functions.jq"
elif [ "$BASH_SOURCE" -nt "$jqf" ]; then
	# https://github.com/docker-library/bashbrew/blob/master/scripts/template-helper-functions.jq
	wget -qO "$jqf" 'https://github.com/docker-library/bashbrew/raw/08c926140ad0af22de58c2a2656afda58082ba3e/scripts/template-helper-functions.jq'
fi

if [ "$#" -eq 0 ]; then
	versions="$(jq -r 'keys | map(@sh) | join(" ")' versions.json)"
	eval "set -- $versions"
fi

generated_warning() {
	cat <<-EOH
		#
		# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
		#
		# PLEASE DO NOT EDIT IT DIRECTLY.
		#

	EOH
}

for version; do
	rm -rf "$version"

	for variant in debian alpine; do
		export version variant

		dir="$version/$variant"

		echo "processing $dir ..."

		mkdir -p "$dir"

		{
			generated_warning
			gawk -f "$jqt" Dockerfile.template
		} > "$dir/Dockerfile"

		cp -a docker-entrypoint.sh "$dir/"
	done
done
