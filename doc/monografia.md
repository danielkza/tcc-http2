# Monografia Preliminar - Implementação do Protocolo HTTP2 na linguagem Scala
- - -
## Aluno: Daniel Q. Miranda - NUSP 7577406
## Orientador: Prof. Dr. Daniel Batista
- - -

### Resumo




### Índice

1. Introdução
2. Motivação  
    1. O protocolo HTTP/2  
        1. Introdução  
        2. Objetivos  
        3. Mecanismos  
            1. Formato binário
            2. Compressão de Headers (HPACK)
            3. Multiplexação e controle de fluxo
            4. Priorização
    2. Tecnologias utilizadas
        1. Linguagem Scala
        2. A plataforma Akka
3. Implementação
    1. Paradigma funcional e imutabilidade
    2. O modelo de Atores
    3. Testes
        1. Verificação de entradas e saídas
        2. Testes de integração com aplicações reais
    4. Compressão de headers (HPACK)
        1. Aplicação da codificação de Huffman sem árvores
    5. Biblioteca de comunicação *Akka I/O*
    6. Controle de fluxo de *streams*
    7. Interface de programação
    8. 


# Introdução

O protocolo de comunicação de rede HTTP/2 foi definido e aceito pela 
Internet Engineering Task Force (IETF) em 2015 ([RFC 7540](http2-rfc)). Com o objetivo de substituir o
HTTP como alicerce da Internet, traz um mecanismo de transmissão totalmente novo
com semântica preservada, buscando melhorias de aproveitamento de recursos,
performance e extensibilidade 

O HTTP/2 define uma representação binária, em contraste com a definição textual
do seu predecessor, e permite a coexistência de múltiplos fluxos de dados simultâneos
através de uma única conexão. Define um método de compressão de *Headers* eficiente
e resistente a ataques contra criptografia, e torna desnecessárias diversas otimizações
inconvenientes que hoje se fazem necessárias para acelerar o carregamento de páginas Web.

Softwares clientes na Internet como browsers e utilitários de download já implementam
o novo protocolo. O suporte em servidores inicia-se mais lentamente, devido a 
maior complexidade envolvida em sua implementação. Mas dois dos mais utilizados
servidores de código-livre, [Apache HTTPD](apache) e [nginx](), já fornecem versões experimentais
do HTTP/2 (em Outubro de 2015).

Este trabalho descreverá uma implementação do protocolo HTTP/2, com facetas de
cliente e servidor, na linguagem de programação orientada a objetos e funcional
[Scala](), utilizando o modelo de atores [@actor-hewitt] implementado pela plataforma
[Akka](). Esta combinação permite elegância e coesão do código, através da composição
de componentes independentes, estágios de processamento compostos organicamente,
e alta performance devido a maturidade da máquina virtual do Java utilizada.

Denominar-se-a daqui para frente o protocolo original HTTP e suas revisões até
1.1 como "HTTP/1". A versão 2 definida em 2015 será mencionada como "HTTP/2", e
aspectos comuns a ambas serão referidos genericamente como "HTTP" 

# Motivação

## O protocolo HTTP/2

Como sucessor do HTTP/1, o HTTP/2 foi desenvolvido para atender a diversos casos
de uso de comunicação na Internet, dos quais um dos mais utilizados é a visualização
de documentos e aplicações na Web. Para alcançar tais objetivos utiliza mecanismos
mais complexos que a comunicação textual delimitada por linhas da primeira versão.

### Formato Binário

O HTTP define objetos a serem transmitidos como conjuntos de *headers*,
parâmetros e informações de um *pedido* ou *resposta* delimitados por linhas,
seguidos de octetos de uma mensagem. Este modelo é suficiente para o caso original
de transmissão de páginas Web simples, mas é falho para representar interações
mais complexas que uma única transmissão de mensagem simultânea.

O HTTP/2 substitui a representação textual por um conjunto de mensagens de formato
binario, que podem definir parâmetros de conexão, transmissão de headers, corpo
de mensagens, abertura de múltiplos canais, e ainda requisição de pré-carregamento
de recursos além do sujeito atual.

### Compressão de Headers

O HTTP/2 define um sub-formato ([HPACK]()) para transmissão de headers de maneira eficiente,
comprimindo-as através de manutenção de tabelas de chaves e valores comuns, e
aplicação de Codificação de Huffman como compressão. Técnicas pré-existentes,
como o uso de algoritmos sobre a mensagem como um todo, são sujeitas a falhas
de segurança (CRIME [@raey], BREACH [@pradossl]), mas este esquema foi definido
de maneira resistente a estes ataques e que exclui conteúdos sensíveis da conversão.

### Multiplexação e controle de fluxo

O HTTP/2 define um sistema de múltiplos fluxos de dados (*streams*) simultâneos.
Eles representam canais de comunicação independentes e bidirecionais, pelos quais
mensagens podem trafegar entre os interlocutores. Transmissões de vários fluxos
podem transitar em uma única conexão TCP através da intercalação de *frames* 
entre eles.

Fluxos podem ser criados e destruídos de maneira individual e (fix: independente)
do ciclo de vida da conexão como um todo. Cada um é atribuído uma *janela de controle de fluxo*,
que pode ser usada por um interlocutor para restringir a velocidade de transmissão de dados
em curso. Um remetente deve restringir suas transmissões caso a janela de um dado
fluxo esteja totalmente utilizada, permitindo, por exemplo, que dispositivos com
recursos escassos não sejam sobrecarregados.

Este mecanismo permite que diversos objetos sejam transmitidos simultaneamente,
como ocorre muito comummente em páginas Web complexas, sem estressar a infraestrutura
da camada de transmissão sobre a qual o HTTP existe.

### Priorização

É possível atribuir dependências e níveis de prioridades a fluxos distintos, indicando
maior importância ou urgência a mensagens neles enviadas.

Fluxos subordinados só podem receber recursos caso seus superiores estejam ociosos
ou em espera. Num mesmo nível da hierarquia, recebem recursos proporcionais a um
valor inteiro atribuído a cada um, representando uma fração do total disponível.
(por exemplo, 3 fluxos de prioridades 3, 5 e 10, respectivamente receberiam
3/18, 5/18 e 10/18 da banda de transmissão disponível)

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

# Implementação

## O paradigma funcional e imutabilidade
## O modelo de Atores
## Testes
### Verificação de entradas e saídas
### Testes de integração com aplicações reais
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
(CRIME [@raey], BREACH [@pradossl]), e portanto essa prática é *banida* no HTTP/2.

Substitui-na o HPACK, que comprime headers individualmente, através da manutenção
de uma tabela de cadeias comuns e previamente observadas em uma conexão. Cadeias
longas ou que não foram observadas anteriormente são comprimidas através da 
Codificação de Huffman [@huffman] com símbolos estáticos, que não é sujeita a 
nenhuma ataque de correlação conhecido. Remetentes podem especificar que certas
chaves são sensíveis e não devem ser comprimidas de nenhuma maneira (como por exemplo
os já mencionados cookies).

### Aplicação da Codificação de Huffman sem árvores

O mapeamento estático de símbolos da Codificação de Huffman do HPACK correlaciona
octetos com códigos que variam entre 5 e 31 bits. Ao contrário dos usos mais comuns
desse algoritmo, onde o mapeamento é construído à partir de cada mensagem a ser
comprimida, a tabela é pré-definida, igual para todas as mensagens, e de tamanho
pequeno (256 entradas, suficientes para um octeto e um símbolo especial de fim
de mensagem).

Estas particularidades permitem que seja adotada uma implementação mais simples
e eficiente que a tradicional. Em vez de construir uma arvore de prefixos com
nós correspondentes a um bit, e processar a entrada bit-a-bit, é possível
particionar os códigos por seu tamanho, ler os dados octeto-a-octeto, e comparar
com a tabela aplicando-se uma máscara.

(falar O(n) vs O(log N), mas constante pequena))

## Biblioteca de comunicação *Akka I/O*
## Controle de fluxo de *streams*
## Interface de programação 

[Akka]: http://akka.io
[Typesafe]: http://typesafe.com
[http2-rfc]: https://tools.ietf.org/html/rfc7540
[WebSocket]: https://www.websocket.org/
[HPACK]: https://http2.github.io/http2-spec/compression.html
[Jetty]: http://eclipse.org/jetty
[Netty]: http://netty.io
[http4s-blaze]: https://github.com/http4s/blaze
[SBT]: http://scala-sbt.org/
[akka-io]: http://doc.akka.io/docs/akka/current/scala/io.html
