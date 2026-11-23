#!/bin/sh
# Compila os serviços de dados com um Auth anônimo e roda contra a API real.
set -e
cd "$(dirname "$0")"
S=../../YTMusicGo/Services
swiftc -parse-as-library -o "${TMPDIR:-/tmp}/ytm-harness" main.swift AuthStub.swift $S/InnerTube.swift $S/Translate.swift $S/Support.swift
"${TMPDIR:-/tmp}/ytm-harness"
