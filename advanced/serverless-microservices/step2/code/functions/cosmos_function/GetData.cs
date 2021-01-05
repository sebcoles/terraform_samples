using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Microsoft.Azure.Cosmos;
using System.Collections.Generic;
using System.Configuration;

namespace cosmos_function
{
    public static class GetData
    {
        private static CosmosClient _cosmosClient;
        private static Database _database;
        private static Container _container;
        private static string databaseId = "microservices-cosmos";
        private static string containerId = "PersonContainer";

        [FunctionName("GetData")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            var mongo_connection_string = ConfigurationManager.AppSettings["mongo_connection_string"];
            _cosmosClient = new CosmosClient(mongo_connection_string);
            _database = await _cosmosClient.CreateDatabaseIfNotExistsAsync(databaseId);
            _container = await _database.CreateContainerIfNotExistsAsync(containerId, "/Name");
            var data = await QueryItemsAsync();

            return new OkObjectResult(data);
        }

        private static async Task<List<Person>> QueryItemsAsync()
        {
            var sqlQueryText = "SELECT * FROM c";
            QueryDefinition queryDefinition = new QueryDefinition(sqlQueryText);
            FeedIterator<Person> queryResultSetIterator = _container.GetItemQueryIterator<Person>(queryDefinition);

            List<Person> people = new List<Person>();

            while (queryResultSetIterator.HasMoreResults)
            {
                FeedResponse<Person> currentResultSet = await queryResultSetIterator.ReadNextAsync();
                foreach (Person family in currentResultSet)
                {
                    people.Add(family);
                }
            }
            return people;
        }

        public class Person
        {
            public int Id { get; set; }
            public string Name { get; set; }
        }
    }
}
