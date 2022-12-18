<h1 align="center">ItauAPIFramework</h1>

## Descrição do Projeto
Disponibiliza a conexão com a API por método post, recebendo alguns dados do hardware do aparelho.

# Usage

```swift
import ItauAPIFramework

ItauService.shared.post(body: data.dictionary) { result in
    switch result {
    case .success(let data):
    case .failure(_):
}
```
