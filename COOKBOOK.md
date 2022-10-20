# Kokebok

## Repoet

Dette repoet er forket ut av [dette](https://github.com/Ontotext-AD/graphdb-docker) prosjektet og tilpasset vår bruk. Et par commits er det åpnet PR-er på i forsøk på å få de upstreamet. 

Les deres egen forklaring på repoet i README.md. Under følger kokeboken for vår egen bruk. 

## GraphDB og CIM

GraphDB er som navnet tilsier en grafdatabase. CIM-filer representerer kort fortalt en graf av komponenter (fysiske og/eller funksjonelle) i strømnettet. Vi laster CIM-filer inn i GraphDB for å ha et litt smidigere verktøy å utforske dataene i, samt et sted å utforme spørringer vi trenger for å hente ut subsettene av informasjon til vår datamodell. 

## How-to

Prosjektet består av følgende filer: 

```
├── COOKBOOK.md             # Denne filen
├── docker-compose.yml      # For å spinne opp graphDB docker imaget
├── Dockerfile              # Deklarasjon for å bygge graphDB docker imaget
├── Makefile                # Makefile for å gjøre operasjoner i repoet
├── preload
│   ├── .env                # Miljøvariabler for import-steget
│   ├── docker-compose.yml  # Kjører import av data til det bygde graphDB imaget
│   ├── graphdb-repo.ttl    # Repository-instillinger som brukes ved import
│   ├── import              # Mappe der filer man vil importere legges
│   └── imported            # Mappe der filer som er blitt importert legges
└── README.md               # Upstream prosjektbeskrivelse
```

For å komme i gang kan man legge filer man ønsker importert til GraphDB i mappen `import`, og deretter kjøre `make`. 

`make` vil bygge docker imaget, importere filene i `import` mappen etter instillingene som finnes i `graphdb-repo.ttl`, flytte importerte filer og til slutt kjøre graphDB- docker containeren med importert data. GraphDB er nå tilgjengelig på [localhost:7200](http://localhost:7200). Dataene ligger som default i repositoriet med navn `CIM`. Legg merke til den nye mappen graphdb-data. Det er her alle data som containeren trenger monteres. 
