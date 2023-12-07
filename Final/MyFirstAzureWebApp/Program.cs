using MyFirstAzureWebApp;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

// Retrieve the connection string
string connectionString = "Endpoint=https://finalappconfig.azconfig.io;Id=L8Ma;Secret=5IoEddje11+Hmr9Rid1IoSZfdAlqqrZdzhcrICR2itk=";

// Load configuration from Azure App Configuration
builder.Configuration.AddAzureAppConfiguration(connectionString);

// Add services to the container.
builder.Services.AddRazorPages();

// Bind configuration "TestApp:Settings" section to the Settings object
builder.Services.Configure<Secrets>(builder.Configuration.GetSection("App:Secrets"));


var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();
