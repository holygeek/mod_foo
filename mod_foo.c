#include "httpd.h"
#include "http_core.h"
#include "http_protocol.h"
#include "http_log.h"
#include "http_request.h"

#define logdebug(MSG) fprintf(stderr,  "> " MSG "\n"); fflush(stderr)
#define logdebugf(FMT, ...) fprintf(stderr,  "> " FMT "\n", __VA_ARGS__); fflush(stderr)
void *foo_create_server_config(apr_pool_t *p, server_rec *s);
static void register_hooks(apr_pool_t *pool);

module AP_MODULE_DECLARE_DATA foo_module =
{
	STANDARD20_MODULE_STUFF,
	NULL,
	NULL,
	foo_create_server_config,
	NULL,
	NULL,
	register_hooks
};

int *nrequest = NULL;
static int foo_handler(request_rec *r)
{
	logdebug("HANDLER");
	if (!r->handler || strcmp(r->handler, "foo-handler"))
		return DECLINED;

	ap_set_content_type(r, "text/plain");
	(*nrequest)++;
	ap_rprintf(r, "Ohai from pid %u! nrequest = %d\n", getpid(), *nrequest);
	logdebugf("nrequest = %d", *nrequest);

	return OK;
}

static void register_hooks(apr_pool_t *pool)
{
	logdebug("REGISTER HOOKS");
	
	ap_hook_handler(foo_handler, NULL, NULL, APR_HOOK_LAST);
}

void *foo_create_server_config(apr_pool_t *p, server_rec *s)
{
	logdebug("CREATING SERVER CONFIG");
	// Doesn't work logdebug("%s", "Is this thing on?")
	if (nrequest != NULL)
	{
		logdebug("ERROR! nrequest should not be NULL anymore - it should only be initialized once");
		exit(1);
	}
	nrequest = apr_palloc(p, sizeof(int));
	*nrequest = 0;
	return s;
}
