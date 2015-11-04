---
title: Monografia Preliminar - Implementação do Protocolo HTTP2 na linguagem Scala
date: Outubro 2015
author: Daniel Q. Miranda
orientador: Prof. Dr. Daniel Macêdo Batista
place: São Paulo, Brasil
institution: Instituto de Matemática e Estatística - Universidade de Sâo Paulo

lang: english,brazil

capa: false
folhaderosto: false
navbar:
  monografia: true
...

# Introdução

O protocolo de comunicação de rede HTTP (HyperText Transfer Protocol) é o
alicerce do funcionamento da Web - e por extensão, de grande parte da Internet -
e define os mecanismos de comunicação utilizados por um enorme número de aplicações
conectadas por redes de computadores. Foi criado como método de
transmissão para documentos, mas hoje carrega todo tipo de mídia - como aplicações
complexas, áudio e vídeo - devido a sua flexibilidade. 

Em 2015 a Internet Engineering Task Force (IETF), grupo de maior influência na
definição de padrões e práticas da Internet, propôs, após mais de 20 anos da 
original, uma nova versão modernizada do HTTP, denominada HTTP/2 [@RFC7540].
Ela mantém a semântica original das mensagens, mas define um novo mecanismo de
transmissão mais eficiente, com melhoras no aproveitamento de recursos,
desempenho, extensibilidade e segurança.

Visando sanar essas deficiências o HTTP/2, dentre outras melhorias:

* Introduz novos mecanismos para explorar ao máximo recursos de rede disponíveis,
  em especial através do paralelismo de transmissões em uma única conexão TCP.
  (vide [Modelo de protocolo da Internet](#Modelo-de-protocolos-da-Internet) e [Multiplexação](#Multiplexação)).

* Substitui uma representação textual, na qual delimitadores de conteúdo e
  definições são sequencias especiais de caracteres, por uma binária,
  onde diversos tipos de mensagens são definidos com métodos de codificação
  individuais. Essa mudança permite a utilização de operações mais complexas, porém
  mais eficientes. (vide [Formato Binário](#Formato-binário))

* Permite que servidores listem de antemão recursos relacionados a outros, para
  que clientes possam adquiri-los em simultâneo. Esse mecanismo visa acelerar
  em especial carregamento de páginas e aplicações Web complexas, que incluem
  dezenas de recursos externos.

* Compressão de metadados (*headers*) eficiente e resistente a ataques contra
  criptografia

O HTTP/2 vem sendo velozmente adotado por diversos projetos de software de grande
utilização, em especial de código-aberto. Navegadores como Chrome e Firefox [@http2-faq]
e servidores como Apache e ngnix [@http2-implementations] o suportam em caráter
final ou experimental. Existem,
porém, oportunidades para novas implementações explorando diferentes metodologias
e aspirações.

Este trabalho descreverá uma implementação do HTTP/2 na linguagem de programação
orientada a objetos e funcional [Scala][], utilizando o modelo de atores [@actor-hewitt]
implementado pelo conjunto de ferramentas [Akka][]. Esta combinação foi escolhida
devido a características como:

* Expressividade da linguagem, permitindo elegância e coesão de implementação
* Eliminação de compartilhamento de dados entre entidades concorrentes,
  facilitando a escalabilidade para múltiplos processadores e máquinas
* Maturidade da plataforma Java e seus ecossistema de software
* Facilidade de uso e eficiência da Akka para criação de sistemas concorrentes
  eficientes

Denominar-se-a daqui para frente o protocolo original HTTP e suas revisões até
1.1 como "HTTP/1". A versão 2 definida em 2015 será mencionada como "HTTP/2", e
aspectos comuns a ambas serão referidos genericamente como "HTTP".

(TODO: inserir citação do site da Akka e/ou exemplos de sistemas)

# Motivação

## O protocolo HTTP/2

Como sucessor do HTTP/1, o HTTP/2 foi desenvolvido para atender a diversos casos
de uso de comunicação na Internet, dos quais um dos mais utilizados é a visualização
de documentos e aplicações na Web. Para alcançar tais objetivos utiliza mecanismos
mais complexos que a comunicação textual delimitada por linhas da primeira versão.

### Formato Binário

O HTTP/1 define objetos a serem transmitidos como conjuntos de *headers*,
parâmetros e informações de um *pedido* ou *resposta* delimitados por linhas,
seguidos de octetos de uma mensagem. Este modelo é suficiente para o caso original
de transmissão de páginas Web simples, mas é falho para representar interações
mais complexas que uma única transmissão de mensagem simultânea.

O HTTP/2 substitui a representação textual por um conjunto de mensagens de formato
binario, que podem definir parâmetros de conexão, transmissão de headers, corpo
de mensagens, abertura de múltiplos canais, e ainda requisição de pré-carregamento
de recursos além do sujeito atual.

## Compressão de Headers (HPACK)

O HTTP/2 define um sub-formato chamado [HPACK]() para transmissão eficiente
de metadados (*headers*) de mensagens, motivado por deficiências de segurança em
métodos utilizados anteriormente em conjunto com encriptação.
Tentativas anteriores de combinar compressão e privacidade mostraram-se
vulneráveis a ataques, que alcançaram a extração de informações através da
observação de padrões estatísticos nos dados comprimidos (CRIME [@raey], BREACH [@pradossl]).

O HPACK supera estas dificuldades utilizando técnicas e algoritmos mais
simples, e talvez menos eficientes, mas que até o presente momento se mostram
resistentes a ataques.

A necessidade de proteção de conteúdo de *headers* se deve principalmente ao uso
dos *cookies* - conjuntos de dados enviados por um servidor para identificar um
cliente, e retransmitidos pelo segundo em toda requisição.

(TODO: Explicação detalhada de cookies baseada no Kurose)

Três mecanismos são utilizados pelo HPACK para diminuir a banda de
transmissão de *headers* sem comprometer a privacidade:

1. **Tabela estática de conteúdos pré-definidos**
    Uma lista de conteúdos mais comuns é compartilhada entre todos os programas
    que implementam o HTTP/2. Cada chave, valor, ou conjunto chave-valor que 
    seja definido na tabela pode ser transmitido somente como um índice inteiro,
    substituindo a cadeia de carácteres usual.

2. **Tabela dinâmica de conteúdos transmitidos na conexão**
    Cada transmissão de *header*, caso uma exceção não seja explicitamente
    requisitada, é armazenada em uma *tabela dinâmica* de entradas. Repetições
    futuras de conteúdos equivalentes podem ser substituídas por um índice,
    explorando semelhanças entre mensagens de uma mesma conexão.

3. **Compressão de literais por codificação de Huffman**
    *Headers* que não possam fazer uso das regras anteriores podem ser
    comprimidas com um *Código de Huffman* simples, com símbolos de substituição
    pré-definidos, escolhidos para máxima compressão com base em amostras de
    tráfego real. Esse esquema não possui nenhuma fraqueza estatística conhecida. 


## Multiplexação

O HTTP/2 define um sistema de múltiplos fluxos de dados (*streams*) simultâneos.
Eles representam canais de comunicação independentes pelos quais múltiplas
mensagens podem trafegar entre os interlocutores simultaneamente, utilizando uma
única conexão TCP. Mensagens de um fluxo são divididas em diversos pacotes (*frames*),  
que então são intercalados com diferentes prioridades.

Diferentemente do HTTP/1 no qual somente o cliente - parte que iniciou a conexão -
pode fazer pedidos, o HTTP/2 permite que servidores iniciem fluxos, facilitando
sua utilização por aplicações que necessitam de comunicação *duplex*, e possibilitando
melhorias de desempenho na transmissão de hierarquias complexas de recursos
(vide [Pré-carregamento](#Pré-carregamento)).

Esta capacidade de multiplexação pode ser considerada uma continuação ou extensão
do *pipelining* definido no HTTP/1.1. Esta prática consiste em permitir que
interlocutores enviem mensagens consecutivos sem aguardar respostas a
cada uma delas, mas ainda exige que todas as mensagens sejam enviadas e processadas
em ordem (*first-in-first-out*). Embora uma melhora significativa em comparação
com o procedimento mais simplístico, o pipelining sofria de deficiências,
como a possibilidade de *head-of-line blocking*, situação onde um pedido excessivamente
custoso impede que outros mais simples sejam processados concomitantemente.

A multiplexação do HTTP/2 remove limitações de ordem, permitindo que mensagens
trafeguem de maneira realmente simultânea e independente, ao custo de complexidade
de implementação servidores e clientes, que precisam gerenciar estado muito
mais complexo.

## Controle de fluxo.

O HTTP/2 define *janelas de controle de fluxo* para a conexão como um todo e cada
fluxo em separado. Elas definem uma capacidade máxima de recepção de dados de um
interlocutor com recursos finitos, de modo que eles não seja esgotados por uma
contraparte de maior poder computacional.

A qualquer momento, um remetente envia um *frame* definindo uma quantidade
de dados, em octetos, que deseja ou consegue receber até segunda ordem. Ao receber
este *frame*, o destinatário deve contabilizar o que envia, e não deve exceder
o volume definido até o recebimento de um novo valor. Em caso de esgotamento,
somente uma *atualização de janela* permite que os envios sejam retomados.

A modalidade individual por fluxo da janela pode ser utilizada também como
mecanismo de priorização, além dos outros já definidos pelo protocolo (vide
[Priorização](#Priorização)). Ao estabelecer um volume máximo atribuído a um
fluxo em um período de tempo, outros podem receber chances de fazer uso
da banda disponível.

Este conceito se assemelha conceitual e praticamente ao controle de fluxo existente
na camada de transporte, como por exemplo no TCP. Sua posição na camada de aplicação
do modelo de rede lhe provém usos e capacidades diferentes, porém.
Ele permite que o controle seja aplicado pela aplicação, e não somente 
por pressão de recursos observada pelo sistema operacional, como é tradicional
na camada de transporte. O HTTP/2 distingue *frames* de dados e controle 
na contagem da janela, o que evita situações de perda de responsividade devido
a proximidade do esgotamento.

## Priorização

É possível atribuir dependências e níveis de prioridades a fluxos distintos, indicando
maior importância ou urgência a mensagens neles enviadas.

Fluxos subordinados só podem receber recursos caso seus superiores estejam ociosos
ou em espera. Num mesmo nível da hierarquia, recebem recursos proporcionais a um
valor inteiro atribuído a cada um, representando uma fração do total disponível.
(por exemplo, 3 fluxos de prioridades 3, 5 e 10, respectivamente receberiam
3/18, 5/18 e 10/18 da banda de transmissão disponível)

(TODO: expandir)

### Pré-carregamento

O HTTP/2 permite que um participante inicie uma transmissão na qual é servidor
- papel geralmente reservado ao cliente - para reduzir o tempo ocioso entre
a recepção de um recurso e a requisição de outros relacionados. Caso um cliente
não rejeite a oferta, a transmissão de headers começa imediatamente, e um fluxo é
reservado para a transmissão dos dados em algum momento futuro.

O principal objetivo dessa funcionalidade é acelerar páginas e aplicações Web
complexas, que incluem dezenas de recursos adicionais como imagens e  *scripts*.
Cada um destes exige uma requisição adicional, incorrendo gasto maior de banda
com *headers*, e pior aproveitamento da conexão devido ao
tempo ocioso entre cada transmissão. Práticas como combinação de imagens tornaram-se
comuns para evitar estes problemas [@w3c-webapp], mas se tornam desnecessárias
com o HTTP/2.

# Tecnologias utilizadas

## A Linguagem Scala

[Scala]() é uma linguagem multi-paradigma, que tem como principal característica
a combinação da orientação a objetos, compatível com a plataforma Java, e da
programação funcional.

Possui um sistema de tipos poderoso, com funções de primeira-classes, tipos 
parametrizados e inferência local, e permite expressar sucintamente programas de
diversos tipos.

Foi escolhida para elaboração desse trabalho devido a alta maturidade do ecossistema
Java e da plataforma Akka, seu alto poder expressivo e foco em estruturas de dados
imutáveis, concorrência e elegância.

## A Plataforma Akka

[Akka]() é uma plataforma que implementa o modelo de atores para criação de sistemas
concorrentes, tolerantes a falhas e de alta escalabilidade em Scala ou Java. Permite
programar fluxos de dados de maneira assíncrona e eficiente, incluindo servidores
TCP como é necessário para utilização do HTTP.

Atores comunicam-se somente através de passagem de mensagens discretas, o que
é conducente a diminuição de dependências e estado compartilhado, e a modularização
dos componentes do software.

(TODO: Expandir)

(TODO: Incluir exemplos de código/fluxograma/modelagem, comparar com outros modelos)


# Implementação

TODO

## O paradigma funcional e imutabilidade

TODO

## O modelo de Atores

Para confecção de um software capaz de fazer uso de múltiplos processadores de
maneira eficiente, correta e elegante, foi utilizado o modelo de atores como
implementado pela plataforma Akka.

Um ator é uma entidade computacional que interage com outras, recebe ou envia
informações somente através de mensagens. Em resposta a uma mensagem, um ator
pode enviar outras, criar novos atores, e/ou modificar seu comportamento para
a próxima recepção. Diferentemente de outros modelos de concorrência, em especial
os de nível mais baixo de abstração, não é definido o compartilhamento de estado
entre os atores. Eles devem se comunicar somente através de mensagens.

Com o Akka atores podem transitar livremente entre threads do sistema operacional em
diferentes processamentos de mensagem, e operações asíncronas (como passagem mensagems)
são modeladas através de *futuros*  da linguagem Scala.

Um futuro encapsula um valor a ser produzido ou uma computação
a ser efetuado em algum momento futuro indeterminado, e permite definir transformações
sobre esse resultado que só serão executadas após sua materialização. Esta combinação
permite que o gerenciamento de threads seja completamente invisível ao programador
se desejado.

O modelo foi aplicado ao HTTP/2 delimitando diferentes atores para gerenciar
cada conexão e cada fluxo. O ator da conexão decodifica frames recebidos, 
determina se devem se aplicam-se a conexão como um todo ou não, e se negativo,
encaminha uma mensagem já decodificada para o ator do fluxo. Isso permite
como que fluxos com diferentes custos e tempos de processamento não bloqueiem
uns aos outros,  e gerenciem o fluxo de dados em ritmos distintos.

[TODO: continuar e elaborar mais]

## Testes

TODO

### Verificação de entradas e saídas

TODO

### Testes de integração com aplicações reais

TODO

## Compressão de headers (HPACK)

A transmissão de headers de mensagens no HTTP/2 é feita através de um protocolo
próprio chamado [HPACK](), criado especificamente para este propósito.
Como no HTTP/1, headers são uma série de chaves e valores definidas por cadeias
de caracteres, representando metadados de uma mensagem, como o formato do conteúdo,
localização, data de modificação, informações dos interlocutores, etc.

Como o HTTP não define um mecanismo para preservação de estado compartilhado entre
múltiplas mensagens, headers são comummente utilizadas para esse fim. Um dos mecanismos
mais populares são os *Cookies*, também mapeamentos entre chaves e valores, que são
enviados por um remetente para que o destinatário possa o identificar, reiniciar uma
sessão anterior, ou reaver qualquer outro tipo de informação. Sua funcionalidade
os torna sensíveis a vazamento, já que protegem acesso a sistemas de todos os tipos
na Web.

A natureza repetitiva destes metadados faz com que sua compressão seja muito 
vantajosa, especialmente para mensagens curtas, ou com metadados semelhantes entre si.
No HTTP/1, durante anos utilizaram-se algoritmos de compressão aplicados sobre uma
mensagem inteira, incluindo corpo e headers, protegida sob um protocolo de confidencialidade
como o TLS. Descobriu-se, porém, que esse esquema é vulnerável a ataques que recuperam
gradativamente informações através da observação da eficiência da codificação.
(CRIME [@raey], BREACH [@pradossl]), e portanto essa prática é **banida** no HTTP/2.

Substitui-na o HPACK, que comprime headers individualmente, através da manutenção
de uma tabela de cadeias comuns e previamente observadas em uma conexão. Cadeias
longas ou que não foram observadas anteriormente são comprimidas através da 
Codificação de Huffman [@huffman] com símbolos estáticos, que não é sujeita a 
nenhuma ataque de correlação conhecido. Remetentes podem especificar que certas
chaves são sensíveis e não devem ser comprimidas de nenhuma maneira (como por exemplo
os já mencionados cookies).

### Aplicação da Codificação de Huffman sem árvores

Para comprimir *headers* que não existem na tabela pré-definida de valores
comuns ou que ainda não foram transmitidas em na conexão atual conexão o HPACK utiliza
uma versão simplificada da Codificação de Huffman, na qual símbolos são de tamanho
fixo (um octeto), e o mapeamento entre símbolos e códigos é fixo.

Estas particularidades permitem substituir a implementação tradicional, utilizando
arvores de prefixos bit-a-bit, por um método que busca octetos completos em vetores
gerados à partir da estrutura da codificação. O número de buscas efetuadas é proporcional
ao número de octetos, e cada busca toma tempo de fator constante. O pré-processamento
é linear, e evita a criação de centenas de nós de uma árvore.

[TODO: diagrama ou pseudo-código]

```

## Biblioteca de comunicação *Akka I/O*

TODO

## Controle de fluxo de *streams*

TODO

## Interface de programação 

TODO

\postextual

# Referências

[Akka]: http://akka.io
[Scala]: http://scala-lang.org
[Typesafe]: http://typesafe.com
[http2-rfc]: https://tools.ietf.org/html/rfc7540
[WebSocket]: https://www.websocket.org/
[HPACK]: https://http2.github.io/http2-spec/compression.html
[Jetty]: http://eclipse.org/jetty
[Netty]: http://netty.io
[http4s-blaze]: https://github.com/http4s/blaze
[SBT]: http://scala-sbt.org/
[akka-io]: http://doc.akka.io/docs/akka/current/scala/io.html

