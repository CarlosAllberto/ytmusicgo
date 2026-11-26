# YTMusicGo

App iOS em SwiftUI (iOS 17+), projeto gerado pelo XcodeGen a partir do `project.yml`.

## Comandos

- Gerar o projeto: `xcodegen generate` (rode depois de mudar o `project.yml` ou adicionar arquivos de recurso)
- Build: `xcodebuild -scheme YTMusicGo -destination 'generic/platform=iOS Simulator' build`
- Testar a camada de dados contra a API real: `scripts/harness/run.sh` (depois de mexer no parser ou quando páginas vierem vazias)

## Convenções

- Comentários no código em português.
- README em dois idiomas: README.md (inglês) e README.pt-BR.md.

## Lista de tarefas

O backlog fica no Linear: workspace "Carlos Alberto", time `CAR`, projeto `YTMusicGo` (use `orca linear`, skill `orca-linear`). Toda issue deste repositório entra no projeto `YTMusicGo`, nunca solta no time, para não misturar com outros projetos. Tipo pela label (`Feature`, `Improvement`, `Bug`). Estados: Backlog = ideia, Todo = próximo, In Progress = agora, In Review = feito por mim, falta você, Done = feito.

O checklist da tarefa atual fica na descrição da própria issue, numa seção `## Etapas` com itens `- [ ]`. Atualize a descrição com `orca linear save-issue CAR-<n> --body-file -` (a descrição é substituída inteira: leia antes com `orca linear issue CAR-<n> --full --json` e preserve o resto).

Em tarefas com várias etapas:
- Antes de começar, crie ou ache a issue, escreva as etapas em `## Etapas` e passe a issue para In Progress.
- Marque cada item assim que terminar e acrescente o que descobrir no caminho.
- Se a conversa for resumida ou você perder o fio, releia a issue In Progress antes de continuar.
- Ao terminar o código, se sobrar algo que só eu posso fazer (ver o resultado na tela, configurar um serviço externo, dar o OK, aplicar algo em produção), escreva uma seção `## Pendências suas` na descrição da issue, com itens `- [ ]` que dizem o que fazer e onde, e passe a issue para In Review. In Review é a minha fila: a issue só vai para Done depois do meu OK. Se não sobrar nada para mim (ex.: mudança interna coberta por testes), passe direto para Done. O "Travado em mim" do resumo repete essas pendências; a fonte é a issue.
- Ao concluir, passe a issue para Done.
- Trabalho novo fora do escopo vira issue nova em Todo no projeto `YTMusicGo`, sem ser resolvido na hora.
- Nunca apague nem cancele issues sem eu pedir.
- Antes de dizer que terminou, rode build e testes e informe o resultado.

Tarefa de um passo só não precisa de checklist.

Ao terminar cada tarefa, organize o resumo em três títulos: Travado em mim, O que mudou, O que encontrei.
