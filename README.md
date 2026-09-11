# Nebo

Source version: `1.1.0`
Language Edition: `1.0`
Publication status: PULL_REQUEST_CANDIDATE
Latest published release: `1.0.1`
Supported target: `x86_64-systemv-elf-linux`

Nebo compila programas para executáveis ELF64 estáticos em Linux x86-64.
O compilador e o runtime nativos usam Assembly/NASM. As ferramentas locais de
SDK, documentação e composição usam Python 3. NASM, GNU ld e Ninja são os
requisitos de build; não há download obrigatório durante o build.

## Compilar e executar

```bash
ninja -j2 neboc
build/bin/neboc --version
build/bin/neboc --version-json
build/bin/neboc check examples/evolution/g10-array-int4.no
build/bin/neboc emit-asm examples/evolution/g10-array-int4.no -o build/array.asm
build/bin/neboc build examples/evolution/g10-array-int4.no -o build/array
./build/array
```

O exemplo termina com código 5, que é o resultado esperado. Em scripts que
tratam qualquer código diferente de zero como falha, esse resultado deve ser
verificado explicitamente. O exemplo público 1.0.1 permanece sem alterações.
Para código novo, use `values.at(index)`. O alias `values[index]` preserva o
acesso por índice inteiro literal a arrays imutáveis de quatro `Int`.

## SDK local

```bash
python3 -B -c 'import subprocess; from compiler.sdk.sdk_builder import NATIVE; subprocess.run(["ninja", "-j2", *NATIVE], check=True)'
python3 -B scripts/build-public-docs.py
python3 -B compiler/sdk/sdk_builder.py build --repo . --neboc build/bin/neboc --output build/sdk-1.1.0 --profile sdk
python3 -B compiler/sdk/sdk_builder.py verify build/sdk-1.1.0
python3 -B scripts/check-version-consistency.py --binary
```

Os dois primeiros comandos preparam as ferramentas nativas e a documentação
offline necessárias ao SDK. Use um diretório de saída novo.
Instalação, upgrade e rollback operam sobre
prefixos locais pertencentes ao utilizador; consulte o
[guia de migração](docs/releases/NEBO-1.1.0-MIGRATION-GUIDE.md).
Nenhum destes comandos publica uma release.

A validação local inclui coleções, dados e streams com resultados observados
e oráculos independentes. Cadeias de chamadas longas e o atlas misto têm
agora análise limitada e diagnósticos verificados.

## Contrato público

A Edition continua a ser 1.0. O âmbito estável de indexing publicado em 1.0.1
foi preservado sem flag especial nem warning por omissão. Indexing geral,
slicing e protocolos de indexing definidos pelo utilizador continuam
reservados. Os módulos experimentais, descritores e testes internos não são
promessas de compatibilidade de source estável.

O único target certificado é Linux x86-64/System V com ELF estático. A
apresentação X11 depende do ambiente. Não há certificação de outro sistema
operativo, GPU, scheduler de produção ou serviços externos.

- [Release notes](docs/releases/NEBO-1.1.0-RELEASE-NOTES.md)
- [Compatibilidade e migração](docs/releases/NEBO-1.1.0-MIGRATION-GUIDE.md)
- [Limitações conhecidas](docs/releases/NEBO-1.1.0-KNOWN-LIMITATIONS.md)
- [Decisão SemVer e evidência](docs/releases/VERSION-DECISION.md)
- [Referência da Edition 1.0](docs/public/v1.0/index.md)
- [Autoridade de versão](version/NEBO-VERSION.json)

## Histórico de publicação

A versão de source 1.1.0 ainda não foi publicada. As releases públicas
[1.0.1](https://github.com/antonioabracos/nebo/releases/tag/nebo-v1.0.1) e
[1.0.0](https://github.com/antonioabracos/nebo/releases/tag/nebo-v1.0.0) permanecem
inalteradas. O [changelog](CHANGELOG.md) preserva as entradas históricas.
