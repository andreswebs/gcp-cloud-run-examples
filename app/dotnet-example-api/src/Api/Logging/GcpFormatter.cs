using Serilog.Formatting;
using Serilog.Templates;

namespace Api.Logging;

public static class GcpFormatter
{
    // TODO:
    // 'logging.googleapis.com/trace_sampled': if @tr is not null then true else undefined(),
    public static ITextFormatter LogEvent { get; } = new ExpressionTemplate(
        """
        {
            {
                severity: if        @l = 'Verbose'     then 'DEBUG'
                          else if   @l = 'Debug'       then 'DEBUG'
                          else if   @l = 'Information' then 'INFO'
                          else if   @l = 'Warning'     then 'WARNING'
                          else if   @l = 'Error'       then 'ERROR'
                          else if   @l = 'Fatal'       then 'CRITICAL'
                          else                              'INFO',
                message: Concat(Coalesce(@m, ''), if @x is not null then Concat('\n', @x) else ''),
                timestamp: UtcDateTime(@t),
                'logging.googleapis.com/trace': if @tr is not null then Concat('projects/', GcpProjectId, '/traces/', @tr) else '',
                'logging.googleapis.com/trace_sampled': undefined(),
                'logging.googleapis.com/spanId': @sp,
                templateId: @i,
                ..rest()
            }
        }
        """ + "\n"
    );
}
