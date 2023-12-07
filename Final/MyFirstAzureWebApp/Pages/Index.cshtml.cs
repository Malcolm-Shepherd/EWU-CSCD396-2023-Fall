using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Options;

namespace MyFirstAzureWebApp.Pages;

public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;
    public Secrets Secrets { get; }


    public IndexModel(IOptionsSnapshot<Secrets> options, ILogger<IndexModel> logger)
    {
        Secrets = options.Value;
        _logger = logger;
    }

    public void OnGet()
    {

    }
}
