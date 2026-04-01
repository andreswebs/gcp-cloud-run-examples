using System.Security.Claims;
using DotnetApiFirebase.Auth;
using DotnetApiFirebase.Helpers;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;
using SerilogTimings;

var builder = WebApplication.CreateBuilder(args);

// Create a temporary logger for startup operations
using var loggerFactory = LoggerFactory.Create(builder => builder.AddConsole());
var startupLogger = loggerFactory.CreateLogger<Program>();

var gcpProjectId = await GcpMetadataHelper.GetProjectIdWithFallbackAsync(builder.Configuration, startupLogger);

try
{
var firebaseProjectId = builder.Configuration["Firebase:ProjectId"] ?? gcpProjectId;
if (string.IsNullOrWhiteSpace(firebaseProjectId) || string.Equals(firebaseProjectId, "unknown", StringComparison.OrdinalIgnoreCase))
{
    startupLogger.LogWarning(
        "Firebase ProjectId is missing or unknown | Set Firebase:ProjectId or GCP project metadata | JwtBearer authority may be invalid");
}

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    options.Authority = $"https://securetoken.google.com/{firebaseProjectId}";
    options.Audience = firebaseProjectId;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidIssuer = $"https://securetoken.google.com/{firebaseProjectId}",
        ValidateAudience = true,
        ValidateLifetime = true,
    };
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var fromForwarded = ForwardedClientJwtBearer.ReadClientJwtForJwtBearer(context.Request);
            if (!string.IsNullOrEmpty(fromForwarded))
            {
                context.Token = fromForwarded;
            }

            return Task.CompletedTask;
        },
    };
});

builder.Services.AddAuthorization();

builder.Services.AddCors(options =>
{
    options.AddPolicy("PocSpa", policy =>
    {
        var origins = builder.Configuration.GetSection("Cors:Origins").Get<string[]>();
        if (origins is { Length: > 0 })
        {
            policy.WithOrigins(origins)
                .WithMethods("GET", "POST", "OPTIONS")
                .WithHeaders("Authorization", "Content-Type", "X-Forwarded-Authorization");
        }
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description =
            "Client Firebase JWT. Behind API Gateway with backend auth, prefer X-Forwarded-Authorization; local tests can send Bearer here.",
    });
});

builder.Services.Configure<HostOptions>(options =>
{
    options.ShutdownTimeout = TimeSpan.FromSeconds(30);
});

builder.Host.UseSerilog((context, config) =>
    config
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.WithProperty("GcpProjectId", gcpProjectId)
);

var app = builder.Build();

var lifetime = app.Services.GetRequiredService<IHostApplicationLifetime>();
lifetime.ApplicationStopping.Register(() =>
    Log.Information("SIGTERM received — draining in-flight requests"));
lifetime.ApplicationStopped.Register(() =>
    Log.Information("Shutdown complete"));

app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto,
});

app.UseCors("PocSpa");

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
            protocol = request.Protocol,
        };

        diagnosticContext.Set("httpRequest", httpRequest, destructureObjects: true);
    });

app.UseAuthentication();
app.UseAuthorization();

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
        service = "dotnet-api-firebase",
        source_ip = sourceIp,
        timestamp = DateTime.UtcNow,
    };

    operation.Complete();
    return response;
});

app.MapGet("/healthz", (ILogger<Program> logger) => {
    using var operation = Operation.Begin("Processing health check request");

    logger.LogInformation("Health check endpoint accessed");

    var response = new {
        service = "dotnet-api-firebase",
        status = "healthy",
        timestamp = DateTime.UtcNow,
    };

    operation.Complete();
    return response;
});

app.MapGet("/api/whoami", (ClaimsPrincipal user) =>
    {
        var claims = user.Claims.Select(c => new { c.Type, c.Value }).ToList();
        return Results.Ok(new
        {
            service = "dotnet-api-firebase",
            authentication_type = user.Identity?.AuthenticationType,
            is_authenticated = user.Identity?.IsAuthenticated ?? false,
            claims,
        });
    })
    .RequireAuthorization();

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
