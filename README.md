# sei5-alpine para DEV

![Resultados do build](https://github.com/pengovbr/sei5-alpine/actions/workflows/publish.yml/badge.svg)

Imagem docker para SEI 5 no PHP82 no Alpine 3.22 - Versão DEV

Essa imagem serve somente para MySQL, MariaDB e Postgres.

Banco sqlserver não tem suporte.

Para banco Oracle usar imagem [sei5-alpine-oracle](https://hub.docker.com/r/processoeletronico/sei5-alpine-oracle).

> **⚠️ ATENÇÃO**
>
> Para banco de dados **SQL Server**, utilize a imagem [sei5-alpine-sqlserver](https://hub.docker.com/r/processoeletronico/sei5-alpine-sqlserver).
>
> Essa imagem **não possui suporte a `ISO-8859-1`** e, por isso, **não funciona corretamente em ambientes que utilizam essa codificação**.
