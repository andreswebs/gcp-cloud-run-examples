using Microsoft.AspNetCore.HttpOverrides;
using Serilog;
using SerilogTimings;
using Api.Helpers;

var builder = WebApplication.CreateBuilder(args);

// Create a temporary logger for startup operations
using var loggerFactory = LoggerFactory.Create(builder => builder.AddConsole());
var startupLogger = loggerFactory.CreateLogger<Program>();

var gcpProjectId = await GcpMetadataHelper.GetProjectIdWithFallbackAsync(builder.Configuration, startupLogger);

try
{
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Host.UseSerilog((context, config) =>
    config
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.WithProperty("GcpProjectId", gcpProjectId)
);

var app = builder.Build();

app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

app.UseSerilogRequestLogging(opts => opts.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        var request = httpContext.Request;
        var remoteIp = request.Headers["X-Forwarded-For"].FirstOrDefault() ??
                       httpContext.Connection.RemoteIpAddress?.ToString();

        var httpRequest = new
        {
            requestMethod = request.Method,
            requestUrl = $"{request.Scheme}://{request.Host}{request.Path}{request.QueryString}",
            userAgent = request.Headers.UserAgent.FirstOrDefault(),
            remoteIp,
            referer = request.Headers.Referer.FirstOrDefault(),
            protocol = request.Protocol
        };

        diagnosticContext.Set("httpRequest", httpRequest, destructureObjects: true);
    });

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/", (HttpContext context, ILogger<Program> logger) => {
    using var operation = Operation.Begin("Processing root endpoint request");

    var sourceIp = context.Request.Headers["X-Forwarded-For"].FirstOrDefault() ?? context.Connection.RemoteIpAddress?.ToString();
    logger.LogInformation("Root endpoint accessed from {SourceIp}", sourceIp);

    var response = new {
        source_ip = sourceIp,
        timestamp = DateTime.UtcNow
    };

    operation.Complete();
    return response;
});

app.MapGet("/healthz", (ILogger<Program> logger) => {
    using var operation = Operation.Begin("Processing health check request");

    logger.LogInformation("Health check endpoint accessed");

    var response = new {
        status = "healthy",
        timestamp = DateTime.UtcNow
    };

    operation.Complete();
    return response;
});

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
