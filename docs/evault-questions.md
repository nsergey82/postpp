# Questions about the eVault System

Based on an analysis of the `evault-core` and `evault-provisioner` packages, here are some specific questions about the eVault system:

### Core Functionality & Architecture

- The `evault-core` README describes eVault as a "secure, distributed data storage and access system". Could you elaborate on the "distributed" aspect? How is data distributed across multiple nodes? What type of consensus mechanism is used?
- What were the key reasons for choosing Neo4j as the data storage backend?
- The data model uses `MetaEnvelope` and `Envelope`. Could you provide some examples of how this hierarchical model is used in practice?
- How is data encrypted at rest and in transit? What encryption algorithms are used?

### W3ID Integration & Security

- How does the W3ID-based authentication and access control work in detail? How are permissions defined and enforced for the GraphQL API and the Neo4j database?
- Are there any plans for supporting other identity and access management systems besides W3ID?
- What measures are in place to prevent common security vulnerabilities, such as injection attacks, broken authentication, and sensitive data exposure?
- The README mentions "regular security audits". Have there been any external security audits of the eVault system?

### Use Cases & Integration

- What are the primary use cases for eVault within the MetaState ecosystem? Which of the platforms (`blabsy`, `eVoting`, etc.) are currently using eVault?
- How would a new application or service integrate with eVault? Are there client libraries or SDKs available, or should developers interact with the GraphQL API directly?
- The `evault-core` README mentions support for "multiple data types and ontologies". Could you provide some examples of the ontologies being used?
- Suppose a use case would require massive scaling, both in volume, variance and throughput. What would be recommendations and best practices to follow?

### Operations & Roadmap

- What is the process for deploying and managing eVault instances in a production environment? How is the `evault-provisioner` used in this process?
- `evault-provisioner` uses Nomad. What was the rationale for choosing Nomad over other container orchestrators like Kubernetes? Would a production deployment require additional services for Service Discovery and Secrets Management?
- What is the long-term roadmap for the eVault system? Are there any major features or architectural changes planned?
