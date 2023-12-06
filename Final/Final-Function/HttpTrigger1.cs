using System;
using System.IO;
using System.Net;
using System.Text.Json.Serialization;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Company.Function
{
    public class HttpTrigger1
    {
        private readonly ILogger _logger;

        public HttpTrigger1(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<HttpTrigger1>();
        }

        [Function("AddReview")]
        public static MultiResponse Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequestData req,
            FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("HttpExample");
            logger.LogInformation("C# HTTP trigger function processed a request.");

            string body = new StreamReader(req.Body).ReadToEnd();
            MyDocument doc = JsonConvert.DeserializeObject<MyDocument>(body)!;
            doc.id = System.Guid.NewGuid().ToString();

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
            response.WriteString(doc.fname);
            response.WriteString(doc.lname);
            response.WriteString(doc.review);

            // Return a response to both HTTP trigger and Azure Cosmos DB output binding.
            return new MultiResponse()
            {
                Document = doc,
                HttpResponse = response
            };
        }
    }
    public class MultiResponse
    {
        [CosmosDBOutput("TestDB", "TestContainer",
            ConnectionStringSetting = "CosmosDbConnectionString", CreateIfNotExists = true)]
        public MyDocument Document { get; set; }
        public HttpResponseData HttpResponse { get; set; }
    }
    public class MyDocument {
        public string id { get; set; }
        public string fname { get; set; }
        public string lname {get; set; }
        public string review {get; set; }
    }
}
