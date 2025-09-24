# eVault protocol

The only way[^1] to access resources on the eVault is by using the eVault protocol.
Currently, we specify only one protocol based on GraphQL, but other protocols may appear later.
We expose operations for creating, updating, deleting, and querying data -- which is stored using the MetaEnvelope and Envelope model; referenced through URIs (usually including eNames/w3ids); protected by access lists (ACLs). Any future protocol (e.g., on top of websockets) will have the same requirements.

## Envelopes / MetaEnvelopes

Envelope: the smallest unit of data in an eVault addressable by its unique identifier (usually local). It is effectively an RDF tripple. When an envelope needs to refer to another resource it uses w3id.
MetaEnvelope: a group of related envelopes. A MetaEnvelope has its own w3id and links to w3ids of all the envelopes in it. Additionally the access list (ACL) of all the envelopes is defined in the MetaEnvelope.

TODO: fix definitions doc w.r.t. ACLs on envelopes

Envelopes in-rest vs. in-transit

## Keys
https://github.com/MetaState-Prototype-Project/prototype/blob/main/infrastructure/evault-core/src/evault.ts#L74
ATM owners can't rotate the public key on the evault (admins can).

## URIs
In many places instead of domain based URIs in the ecosystem we use w3ids [link](link). A w3id can resolve to an eVault location, e.g., ip address and port, or it can resolve directly to a MetaEnvelope on the eVault. Other standard parts of URIs apply., 
TODO: can really reference a single envelope in a meta envelope? should we?

## ACL


https://github.com/MetaState-Prototype-Project/prototype/blob/main/infrastructure/evault-core/src/protocol/vault-access-guard.ts#L58 -- check if well tested. What if non-platform injects user?

The moment the data leaves the eVault, there is no technical way to guarantee ACLs are respected. In particular, platforms handling our data can violate ACL limitations. The protection against that is socioeconomic (e.g., through eReputation). For example, at the moment only accredited platforms have access to user eVaults.

platforms always have access, users accessing "directly" need to be explicitly in the ACL.

TODO: platforms needs to be able to read ACLs for  resources, or else they can't form their own auth models when scanning data formed by other platforms. They have access to all the data, so access to that metadata is not much worse as a privacy violation. [see](https://github.com/MetaState-Prototype-Project/prototype/issues/351)

## Endpoints

## Requester authentication
In the prototype we mainly consider platforms as agents accessing the eVaults.
For each request a platform needs to prove it is accredited.
JWT, refresh. Replay possible withing 15 minutes window.

what does jose.jwtVerify(token, JWKS) do exactly? why is jwks in "registry" part? And yet it looks like it is on every localhost? Will it do chain of trust traversal for certificates? Or just check validity trivially?

Note: context is set [here](https://github.com/MetaState-Prototype-Project/prototype/blob/main/infrastructure/evault-core/src/protocol/graphql-server.ts#L298) the names are [vague](https://github.com/MetaState-Prototype-Project/prototype/issues/353)

[^1]: In the prototype and certain implementations of the eVault it is possible for a person with elevated permissions on real or virtual machines that host the eVault to get direct access to the data of the eVault. The goal is to gradually introduce enough obfuscation and encryption to make this extremely unlikely.

## Awareness
https://github.com/MetaState-Prototype-Project/prototype/blob/main/infrastructure/evault-core/src/protocol/graphql-server.ts#L62
I don't like that we use URIs to identify platforms instead of their w3ids. And https://github.com/MetaState-Prototype-Project/prototype/blob/main/infrastructure/evault-core/src/protocol/graphql-server.ts#L193 should be avoidable
The fanout of "webhook" calling by the evault is crazy. This certainly should be an infrastructure service asap. Also, no retry on failures?!

## pagination
we probably want to support pagination for all requests that can return large values, long lists -- e.g. all envelope ids, all evaults in the universe, etc.

## References
* [Definitions](https://izi.synology.me:792/oo/r/10oUxriiBS7uiWfga7LMq0zDaFNWIaFa)
* [Adapter](https://izi.synology.me:792/oo/r/12tKk7UaMYtndluuLWcDyWXkE22DeS92)
* [Protocol](https://izi.synology.me:792/oo/r/14D44eyiOiPZuqTtCspAlCdawk3TaKNh)
* [Auth](https://izi.synology.me:792/oo/r/13RpvpLDbNmrATjH7L9V1MJiBWZU9UzI#heading_id=VxPajDzE1b)
