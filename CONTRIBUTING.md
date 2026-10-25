# Contribuindo com a feira

Obrigado por querer melhorar a Banca do Capricho! Este é um projeto de teste utilizando o Astra. Contribuições humanas e assistidas por IA são bem-vindas; o comportamento precisa ser verificável e o jogo deve continuar simples de executar.

## Comece por aqui

1. Faça um fork e clone o repositório.
2. Instale Godot 4.7.2 padrão e Python 3.
3. Execute `sh tools/godot.sh` e jogue uma partida.
4. Crie uma branch para sua alteração.
5. Leia [AGENTS.md](AGENTS.md) para entender as responsabilidades de cada componente.

## O que combina com o projeto

Correções de bugs, melhorias de acessibilidade, arte procedural, ajustes de jogabilidade, documentação e validação em outras plataformas. Para mudanças grandes, abra uma issue antes de investir na implementação.

Preserve a experiência offline, a interface em português brasileiro e o ciclo menu → partida de 180 segundos → resultados → reinício. Evite dependências externas, assets sem origem clara e novos serviços de infraestrutura.

## Antes de enviar um PR

```sh
python3 tools/test.py
```

Se mudar gameplay, adicione testes de comportamento relevantes. Se mudar o visual, execute também:

```sh
sh tools/godot.sh --script res://tests/test_game.gd -- --visual
```

Inspecione as capturas em `artifacts/` e descreva o que foi validado. Não declare testes que não executou. Não inclua o motor Godot, caches, credenciais, builds ou gravações brutas no commit. Os arquivos `.gd.uid` são versionados. Apenas mídia pública selecionada deve ir para `docs/media/`.

Use tabs em GDScript, tipos explícitos quando houver ambiguidade e commits que descrevam a mudança. No PR, explique o problema, o comportamento final e os testes executados. Ao usar assistência de IA, revise o código e indique o uso quando isso ajudar a entender a contribuição.

## Reportando bugs

Inclua passos para reproduzir, resultado esperado, resultado observado, versão do Godot e sistema operacional. Se possível, anexe uma captura e o trecho relevante do log, removendo informações pessoais.

## Licença

Ao enviar uma contribuição, você concorda em disponibilizá-la sob a licença MIT deste projeto. Seja respeitoso nas discussões e mantenha o foco no trabalho.
