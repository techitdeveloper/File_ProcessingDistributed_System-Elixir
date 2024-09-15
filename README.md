# FileProcessor

FileProcessor is an asynchronous and distributed application for processing CSV files. It's designed to be deployed across multiple machines for parallel processing, ensuring non-duplicate tasks and efficient data handling.

## Project Highlights
* Asynchronous and distributed architecture.
* Fault-tolerant design with automatic process restarts.
* Scalable to handle multiple CSV sources and processing tasks.
* Move corrupted files to error directory.
* Real-time exchange rate updates for accurate currency conversion.
* Data integrity measures to prevent incomplete, duplicate, or corrupt data.

## Key Features
### 1. CSV Fetching
* Fetch CSV files from multiple API endpoints.
* Dynamic addition of new CSV sources.
* Scheduled daily downloads.
* Flexible handling of varying CSV formats.
* Local storage of downloaded files.
* Retry mechanism for failed csv files.

### 2. CSV Processing
* Processing of locally stored CSV files.
* Real-time currency conversion using latest exchange rates.
* Mapping of CSV columns to database schema.
* Local storage for corrupted files.
* Efficient bulk insertion and updates to the database.
* Memory cleanup after processing.
* Retry mechanism for failed csv files.

## 3. Exchange Rate Updates
* Daily fetching and updating of currency exchange rates.
* Storage of exchange rates in the database for quick access.
* Retry mechanism for failed cases.

## 4 Distributed Processing
* Use of Horde for distributed registry and supervision.
* Libcluster for automatic clustering of nodes.
* Even distribution of tasks across available nodes.

## 5 Fault Tolerance
* Automatic restart of failed processes.
* Handling of network failures and API downtime.
* Handling of corrupted files.
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

### 5. Start the Application
```
  iex -S mix
```

## Running in a Distributed Environment

### 1. Start first node
```
  iex --name node1@127.0.0.1 -S mix
```
### 2. Start another node
```
  iex --name node2@127.0.0.1 -S mix
```
Repeat this step for as many nodes as you want to add, changing the node name each time.

## Adding CSV Sources
To add a new CSV source, use the FileProcessor.Api.add_csv_source/1 function:
```
  FileProcessor.Api.add_csv_source("http://example.com/new_csv_source.csv")
```

## Removing CSV Sources
To remove a CSV source, use the FileProcessor.Api.remove_csv_source/1 function:
```
  FileProcessor.Api.remove_csv_source("http://example.com/new_csv_source.csv")
```

## Listing CSV Sources
To list all current CSV sources, use the FileProcessor.Api.list_csv_sources function:
```
  FileProcessor.Api.list_csv_sources()
```

## Monitoring
The application uses Elixir's Logger for comprehensive logging. Monitor the console output or configure a more advanced logging solution as needed.
