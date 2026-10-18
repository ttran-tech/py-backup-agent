# py-backup-agent

## Execution Flowchart
```mermaid
flowchart TD
    A["Windows Task Scheduler"] --> B["BackupAgent.exe"]
    B --> C["Initialize Logging"]
    C --> D["Discover JSON Configurations"]
    D --> E["Load & Validate Configurations"]
    E --> F{"Valid jobs available?"}
    F -- No --> X["Record Error"]
    F -- Yes --> G["Iterate Backup Jobs"]
    G --> H["Identify Application Module"]
    H --> I{"Module exists & loads?"}
    I -- No --> J["Record Job Failure"]
    I -- Yes --> K["Execute module.run(params)"]
    K --> L{"Execution successful?"}
    L -- Yes --> M["Record Job Success"]
    L -- No --> J
    J --> N{"More jobs?"}
    M --> N
    N -- Yes --> G
    N -- No --> O["Aggregate Results & Logs"]
    X --> O
    O --> P["Generate Final Summary"]
    P --> Q["Send Discord Notification"]
    Q --> R["Exit with Status Code"]

    classDef entry fill:#dbeafe,stroke:#2563eb,color:#1e40af
    classDef process fill:#f1f5f9,stroke:#64748b,color:#334155
    classDef decision fill:#fef3c7,stroke:#d97706,color:#92400e
    classDef success fill:#dcfce7,stroke:#16a34a,color:#166534
    classDef failure fill:#fee2e2,stroke:#dc2626,color:#991b1b
    class A,B entry
    class C,D,E,G,H,K,N,O,P,Q,R process
    class F,I,L decision
    class M success
    class X,J failure
  ```