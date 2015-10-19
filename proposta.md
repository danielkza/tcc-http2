# Proposta de Trabalho - Implementação do Protocol HTTP2 na linguagem Scala
- - -
## Aluno: Daniel Q. Miranda - NUSP 7577406
## Orientador: Prof. Dr. Daniel Batista
- - -
# Contexto

O recém finalizado protocolo <a href="http://http2.github.io/">HTTP/2</a> foi criado para suceder o mais importante e
utilizado protocolo de comunicação de aplicações em rede na Internet,
o HTTP, modernizando-o com melhorias de eficiência e segurança para o
futuro.

Diversas implementações preliminares do HTTP/2 acompanharam seu
desenvolvimento, em múltiplas linguagens e ecossistemas de
programação, inclusive para a plataforma Java, fazendo uso da
linguagem homônima. Existe, porém, uma certa desconexão dos métodos e
técnicas desta e de outras linguagens que fazem uso da Java Virtual
Machine, em especial as de paradigma funcional, que prezam princípios
como imutabilidade, separação de lógica e E/S, etc.

# Proposta

Me proponho a implementar uma biblioteca e/ou servidor HTTP/2 na
linguagem Scala. Preferencialmente buscarei trabalhar para que ela
seja integrada ao projeto <a href="http://akka.io">Akka</a>), muito popular
framework de concorrência e computação distribuída na JVM, que
recentemente iniciou um projeto de implementação de HTTP combinando
esforços de diversos outros projetos e frameworks de aplicações Web.
Caso isso não seja possível, a desenvolverei de maneira independente.

# Aspectos de Estudo

* Funcionamento do protocolo HTTP/2, incluindo novos desenvolvimentos como compressão
* Estudo da implementação eficiente de protocolos e servidores de rede
* Aplicação e avaliação de técnicas de *[Reactive Programming](http://www.reactivemanifesto.org/)() na eficiência
de comunicação, em especial na plataforma JVM

# Cronograma Aproximado

* Mar-Abr: Estudo preliminar, estudo do projeto Akka e conversa com desenvolvedores para verificar viabilidade de integração
* Abr-Maio: Design inicial de arquitetura, planejamento, estudo do protocolo
* Maio-Jul: Design de APIs, detalhamento da arquitetura, prototipação inicial
* Jul-Out: Implementação de biblioteca já funcional, incluindo maior partes das features possível
  * Múltiplos streams (multiplexing)  
  * Compressão de Headers  
  * *Server Push*  
  * HTTP2c (TLS)  
* Out-Nov: Otimizações de performances, testes e comparações com outras implementações, elaboração de estudos de arquitetura,
integração com algum software pré-existente para testes
