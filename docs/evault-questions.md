# Questions about the eVault System

Based on an analysis of the `evault-core` and `evault-provisioner` packages, here are some specific questions about the eVault system:

### Core Functionality & Architecture

- The `evault-core` README describes eVault as a "secure, distributed data storage and access system". Could you elaborate on the "distributed" aspect? How is data distributed across multiple nodes? What type of consensus mechanism is used?
Every evault is a different server -- specifically in the protype an ephemeral container with persistent volume. Evaults can be distributed across different clouds. Morever, in future, for scaling and disaster recovery each evault will have more than one copy.
  
- What were the key reasons for choosing Neo4j as the data storage backend?
We have a document discussing it. Essentially, our contractors started with PostgreSQL, then tried NoSQL, and ended up with Neo4J due its maturity, ease of use, and most importantly out of the box support for linked data and semantic queries. 

- The data model uses `MetaEnvelope` and `Envelope`. Could you provide some examples of how this hierarchical model is used in practice?
For example in our toy chatting platforms a post with all its metadata is a metaenvelope. The date of the post or the text of the post and other fields (including nested structures) will be envelopes. It can absolutely be done using only envelopes, like and RDF storage does, but introducing them simplified certain things. 

- How is data encrypted at rest and in transit? What encryption algorithms are used?
At the moment there is no encryption at rest. At transit we rely on TLS -- evault are esentially https servers.

### W3ID Integration & Security

- How does the W3ID-based authentication and access control work in detail?
We have a doc about this in this repo, but a more detailed one is not there, we are working on migrating it to markdown and github. In one sentence: we use third-party service Veriff to do identity parsing from a passport and then bind this with private/public key pair. From there it is pretty much OIDC
 
- How are permissions defined and enforced for the GraphQL API and the Neo4j database?
The database is not shared -- each evault has its own. There is no way to access the data in the db from outside. The evault engine can check if the requester is entitled. Furthermore, the platform is a second line of defense. 

- Are there any plans for supporting other identity and access management systems besides W3ID?
We would love to, but we have a very strict set of requirements -- for now we couldn't find anything we like.

- What measures are in place to prevent common security vulnerabilities, such as injection attacks, broken authentication, and sensitive data exposure?
Common mitigation where applicable

- The README mentions "regular security audits". Have there been any external security audits of the eVault system?
We discussed the architecture with experts. But our concrete prototype implementation was not reviewed yet -- simply since it is too early, we are aware of limitations. 

### Use Cases & Integration

- What are the primary use cases for eVault within the MetaState ecosystem? Which of the platforms (`blabsy`, `eVoting`, etc.) are currently using eVault?
Everything is using the evault. Evault is the main thing, there is nothing without the evault, you can't even create an ID for a user without an evault.

- How would a new application or service integrate with eVault? Are there client libraries or SDKs available, or should developers interact with the GraphQL API directly?
No SDK yet, but there is a helper library. There are two different approaches -- a) green field, where a new platform indeed talks evault protocol (graphql) or b) exising platform with a normal database writes a two-way adapter (we have a few examples) that syncs data between db and evaults. 

- The `evault-core` README mentions support for "multiple data types and ontologies". Could you provide some examples of the ontologies being used?
https://schema.org/SocialMediaPosting

- Suppose a use case would require massive scaling, both in volume, variance and throughput. What would be recommendations and best practices to follow?
We are fairly sure that existing prototype can't handle it. However, we hope that the improvements in the "real" system can be transparent to developers.

### Operations & Roadmap

- What is the process for deploying and managing eVault instances in a production environment? How is the `evault-provisioner` used in this process?
- `evault-provisioner` uses Nomad. What was the rationale for choosing Nomad over other container orchestrators like Kubernetes? Would a production deployment require additional services for Service Discovery and Secrets Management?
- What is the long-term roadmap for the eVault system? Are there any major features or architectural changes planned?
The answer to all three is: it is only a prototype. Architecture will be reworked for sure. The ideology and philosophy will remain the same.

