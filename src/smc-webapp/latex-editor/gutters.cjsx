###
Manage codemirror gutters that highlight latex typesetting issues.

NOTE: If there are multiple errors/warnings/etc., on the SAME line, only the last
one gets a gutter mark, with pref to errors.  The main error log shows everything, so this should be OK.
###

misc    = require('smc-util/misc')

{React} = require('../smc-react')
{Icon, Tip} = require('../r_misc')

{SPEC}  = require('./errors-and-warnings')

{required, defaults} = misc

exports.update_gutters = (opts) ->
    opts = defaults opts,
        path       : required
        log        : required
        set_gutter : required
    path = misc.path_split(opts.path).tail
    for group in ['typesetting', 'warnings', 'errors']  # errors last so always shown if multiple issues on a single line!
        for item in opts.log[group]
            if misc.path_split(item.file).tail != path
                continue
            if not item.line?
                continue
            opts.set_gutter(item.line - 1, component(item.level, item.message, item.content))

component = (level, message, content) ->
    spec = SPEC[level]
    if not content?
        content = message
        message = misc.capitalize(level)
    # NOTE/BUG: despite allow_touch true below, this still does NOT work on my ipad -- we see the icon, but nothing
    # happens when clicking on it; this may be a codemirror issue.
    <Tip
        title         = {message ? ''}
        tip           = {content ? ''}
        placement     = {'bottom'}
        icon          = {spec.icon}
        stable        = {true}
        popover_style = {marginLeft:'10px', border:"2px solid #{spec.color}"}
        delayShow     = {0}
        allow_touch   = {true}
    >
        <Icon name={spec.icon} style={color:spec.color, cursor:'pointer'}/>
    </Tip>