# [Backstage](https://backstage.io)

This is your newly scaffolded Backstage App, Good Luck!

To start the app, run:

```sh
yarn install
yarn dev
```

## backstage-dev

https://github.com/victoronl/backstage-dev

Repositório Backstage com templates para deploy de sites estáticos usando AWS (S3, Codecommit/GitHub, Codepipeline) ou GCP (Cloud Storage, Cloud Build, GitHub).

### Templates:

- Cria um repositório para site estático
- Copia para o repositório os arquivos padrão do site estático.
- Cria os arquivos terraform customizados.
- Cria um pull request com os arquivos terraform no victoronl/backstage-devops.

## backstage-devops

https://github.com/victoronl/backstage-devops

Repositório recebe pull requests de templates processados pelo victoronl/backstage-dev e realiza deploy da infraestrutura AWS/GCP.

### Terraform:

- Cria um bucket.
- Cria e aplica permissões de acesso no bucket.
- Cria configuração de site estático no bucket.
- Cria trigger de deploy no Cloud build/Codepipeline.

## Observações

Durante os estudos sobre o Backstage observei diversas melhorias podem ser facilmente implementadas de acordo com a necessidade do cliente, integração direta via SDK com os provedores, criar INPUTS (Backstage) personalizados que permitem a consulta de buckets já existentes no momento do cadastro de um novo site estático, criar ACTIONS (Backstage) personalizados para criar os buckets, permissões e triggers eliminando a necessidade de terraform e um servidor de deploy da infraestrutura, AWS e GCP já oferecem as SDKs necessárias.
