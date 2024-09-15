# FileProcessor

## Setup Instructions
### 1. Clone the repository 
```
  https://github.com/techitdeveloper/File_ProcessingDistributed_System-Elixir.git
  cd file_processor
```
### 2. Install Dependencies
```
  mix deps.get
```
### 3. Configure Database - Edit config/config.exs and update the database credentials: 
```
  config :file_processor, FileProcessor.Repo,
  username: "your_username",
  password: "your_password",
  hostname: "localhost"
```

### 4. Create and Migrate Database 
```
  mix ecto.create
  mix ecto.migrate
```

### 5. Start the Application **
```
  iex -S mix
```

## Running in a Distributed Environment

### 1. Start first node
```
  iex --name node1@127.0.0.1 -S mix
```
### 2. Start first node
```
  iex --name node2@127.0.0.1 -S mix
```
Repeat this step for as many nodes as you want to add, changing the node name each time.

## Adding CSV Sources
To add a new CSV source, use the FileProcessor.Api.add_csv_source/1 function:
```
  FileProcessor.Api.add_csv_source("http://example.com/new_csv_source.csv")
```

## Monitoring
The application uses Elixir's Logger for comprehensive logging. Monitor the console output or configure a more advanced logging solution as needed.