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
│   ├── .env                # Miljøvariabler for import-steget
│   ├── docker-compose.yml  # Kjører import av data til det bygde graphDB imaget
│   ├── graphdb-repo.ttl    # Repository-instillinger som brukes ved import
│   ├── import              # Mappe der filer man vil importere legges
│   └── imported            # Mappe der filer som er blitt importert legges
└── README.md               # Upstream prosjektbeskrivelse
```

For å komme i gang kan man legge filer man ønsker importert til GraphDB i mappen `import`, og deretter kjøre `make`. 

`make` vil bygge docker imaget, importere filene i `import` mappen etter instillingene som finnes i `graphdb-repo.ttl`, flytte importerte filer og til slutt kjøre graphDB- docker containeren med importert data. GraphDB er nå tilgjengelig på [localhost:7200](http://localhost:7200). Dataene ligger som default i repositoriet med navn `CIM` (dette kan overstyres med `make REPONAME=NAVN`). Legg merke til den nye mappen graphdb-data. Det er her alle data som containeren trenger monteres. 

## SparQL

Sparql er spørrespråket som brukes opp mot GraphDB, og også det vi bruker i vår `CIMImporter` applikasjon. 

Ressurser for å tilnærme seg SparQL kan finnes her, her og her. 

For å eksemplifisere så bryter vi ned følgende spørring linje for linje

```
PREFIX cim:<http://iec.ch/TC57/2013/CIM-schema-cim16#>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT ?ACLineId ?ACLineName ?NominalVoltage <
WHERE { 
    ?ACLineId rdf:type cim:ACLineSegment .
    ?ACLineId cim:IdentifiedObject.name ?ACLineName . 
    ?ACLineId cim:ConductingEquipment.BaseVoltage ?BaseVoltage .
    ?BaseVoltage cim:BaseVoltage.nominalVoltage ?NominalVoltage . 
}
```
Men først litt innføring. 

### Triplets
Sparql-spørringer[1] består av såkalte *triplets*. Hver triplet (trilling?) er igjen oppdelt i *subject*, *predicate* og *object*. Sammen uttrykker dette en påstand. Et eksempel kan være
```
subject    predicate    object
 Arne       Eier         Bil
```

I praksis skal alle disse elementene deklareres med en full URI for å (i teorien) være entydige. Så en fullstendig triplet-påstand kan derfor se slik ut
```
              subject                                     predicate                                  object
http://folkeregisteret.no/personer#Arne    http://norskelover.no/eiendomsrett#eier      http://naf.no/bil/register#HS8601
```
Som illustrert kan dette bli i overkant verbose. Det er her første linje i eksempelet vårt kommer inn. 

### Prefix
```
PREFIX cim:<http://iec.ch/TC57/2013/CIM-schema-cim16#>
```
Er rett og slett en mapping eller forkortelse som tilsier at hele URI-en kan referes til med prefiksen `cim`. 

Overført til vårt bileierskapseksempel så kunne en slik prefix sett slik ut
```
PREFIX person:<http://folkeregisteret.no/personer#>
PREFIX eiendomsrett:<http://norskelover.no/eiendomsrett#>
PREFIX bil:<http://naf.no/bil/register>#
```
Vi kan nå uttrykke litt mer lesbart og si at 
```
person:Arne    eiendomsrett:eier    bil:HS8601
```

### Where
Vi sparer SELECT-linjen til senere. La oss ta en titt på WHERE-blokken istedet

Første linje i denne blokken ser slik ut
```
 subject      predicate        object
?ACLineId     rdf:type     cim:ACLineSegment .
```
Vi vet at dette kan leses som at `?ACLineId` er av typen (som definert i `rdf:type`) `cim:ACLineSegment`. 
Predicate og object er tydelige, men subject er på et uvanlig format. I sparql er dette et *wildcard*. Det kan ses på som en placeholder eller en variabel. Denne kan inneholde en verdi, eller et objekt (i praksis en URI til en annen ressurs i databasen). Punktum på slutten er bare for å skille hver triplet nedover i blokken. 

I neste linje drar vi nytte av dette 
```
 subject              predicate               object
?ACLineId     cim:IdentifiedObject.name     ?ACLineName . 
```
I stedet for at subject på neste linje er én bestemt ressurs, er `?ACLineId` en placeholder for alle ressurser som matchet forrige linje i where-klausulen vår. Det denne linjen da gjør er å lagre *object* til variabelen `?ACLineName` for *predikatet* `cim:IdentifiedObject.name` for alle N instanser i placeholderen `?ACLineId`. 

Det er verdt å merke seg at om linje to hadde stått alene uten konteksten av første linje så ville vi istedet matchet på alle subjekter med predikatet `cim:IdentifiedObject.name`. 

La oss nå se på de to neste linjene i sammenheng

```
?ACLineId cim:ConductingEquipment.BaseVoltage ?BaseVoltage .
?BaseVoltage cim:BaseVoltage.nominalVoltage ?NominalVoltage . 
```
Her skjer mye av det samme som på linje to, men mens `?ACLineName` mest sannsynlig var en streng vi var interesserte i så viser det seg at `?BaseVoltage` som `cim:ConductingEquipment.BaseVoltage` deklarerer er en URI (referanse) til en annen ressurs i datasettet. Denne har igjen en predikatdeklarasjon gjennom `cim:BaseVoltage.nominalVoltage` som vi lagrer i variabelen `?NominalVoltage`. `?NominalVoltage` er tallverdien vi til slutt var interesserte i. 

Where-blokken kan inneholde en del annet, blant annet filtreringsmuligheter for antall returnerte ressurser, filtrering på verdier over eller under threshold eller lignende, men vi sparer det til senere. 

### Select
```
SELECT ?ACLineId ?ACLineName ?NominalVoltage 
```
Til slutt er SELECT-statementet vi hoppet over på veien. Dette er rett og slett hvilke av wildcardene vi har samlet lenger ned i spørringen vi ønsker skal være med i outputen vår. I god SQL-stil kan man ta snarveien og si `SELECT *` for å ha med alt. Eksempeloutput på spørringen i sin helhet kan se sånn ut. 

![](https://i.imgur.com/gzQY24J.png)

Hvem som er ansvarlig for navngivning av ACLines i dette datasettet må gudene vite. 


[1] Mer presist vil det være å si informasjonen vi spør i er lagret som triplets. 