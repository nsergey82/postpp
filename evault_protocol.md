# eVault protocol

The only way[^1] to access resources on the eVault is by using the eVault protocol.
Currently, we specify only one protocol based on GraphQL, but other protocols may appear later.
We expose operations for creating, updating, deleting, and querying data -- which is stored using the MetaEnvelope and Envelope model; referenced through URIs (usually including eNames/w3ids); protected by access lists (ACLs). Any future protocol (e.g., on top of websockets) will have the same requirements.

## Envelopes / MetaEnvelopes

Envelope: The smallest unit of data in an eVault addressable by its unique identifier (local or global) and ontology reference. Each envelope has an attached ontological definition and ACL which defines who is allowed to access this envelope.

MetaEnvelope: To group related pieces of data every envelope is associated with a single MetaEnvelope. A MetaEnvelope has its own w3id and links to w3ids of all the envelopes in it.

TODO: are ACLs really on envelope level? maybe need to fix definitions doc

## URIs
Resources are referenced by URI with an addition of the w3id scheme [link](link). A w3id can resolve to an eVault location, e.g., ip address and port, or it can resolve directly to a MetaEnvelope on the eVault. Other standard parts of URIs apply., 
TODO: can really reference a single envelope in a meta envelope? should we?
## ACL

MetaEnvelopes have them but no envelopes? Both?

Envelopes in-rest vs. in-transit

https://github.com/MetaState-Prototype-Project/prototype/blob/main/infrastructure/evault-core/src/protocol/vault-access-guard.ts#L58 -- check if well tested. What if non-platform injects user?



The moment the data leaves the eVault, there is no technical way to guarantee ACLs are respected. In particular, platforms handling our data can violate ACL limitations. The protection against that is socioeconomic (e.g., through eReputation). For example, at the moment only accredited platforms have access to user eVaults.

## Endpoints

## Requester authentication
In the prototype we only considers platforms as agents accessing the eVaults.
For each request a platform needs to prove it is accredited.
JWT, refresh. Replay possible withing 15 minutes window.

what does jose.jwtVerify(token, JWKS) do exactly?

[^1]: In the prototype and certain implementations of the eVault it is possible for a person with elevated permissions on real or virtual machines that host the eVault to get direct access to the data of the eVault. The goal is to gradually introduce enough obfuscation and encryption to make this extremely unlikely.

## References
* [Definitions](https://izi.synology.me:792/oo/r/10oUxriiBS7uiWfga7LMq0zDaFNWIaFa)
* [Adapter](https://izi.synology.me:792/oo/r/12tKk7UaMYtndluuLWcDyWXkE22DeS92)
* [Protocol](https://izi.synology.me:792/oo/r/14D44eyiOiPZuqTtCspAlCdawk3TaKNh)
* [Auth](https://izi.synology.me:792/oo/r/13RpvpLDbNmrATjH7L9V1MJiBWZU9UzI#heading_id=VxPajDzE1b)
