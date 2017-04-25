###
Drag'n'Drop dropzone area
###

ReactDOMServer = require('react-dom/server')   # for dropzone below
Dropzone       = require('dropzone')
DropComponent  = require('react-dropzone-component')

misc           = require('smc-util/misc')

{React, ReactDOM, rclass, rtypes} = require('./smc-react')

{Tip} = require('./r_misc')

Dropzone.autoDiscover = false

DROPSTYLE =
    border       : '2px solid #ccc'
    boxShadow    : '4px 4px 2px #bbb'
    borderRadius : '5px'
    padding      : 0
    margin       : '10px'

render_header = ->
    <Tip
        icon      = 'file'
        title     = 'Drag and drop files'
        placement = 'top'
        tip       = 'Drag and drop files from your computer into the box below to upload them into your project.  You can upload individual files that are up to 30MB in size.'>
        <h4 style={color:"#666"}>
            Drag and drop files (Currently, each file must be under 30MB; for bigger files, use SSH as explained in project settings.)
        </h4>
    </Tip>


exports.SMC_Dropzone = rclass
    displayName: 'SMC_Dropzone'

    propTypes:
        project_id           : rtypes.string.isRequired
        current_path         : rtypes.string.isRequired
        dropzone_handler     : rtypes.object.isRequired
        close_button_onclick : rtypes.func

    dropzone_template : ->
        <div className='dz-preview dz-file-preview'>
            <div className='dz-details'>
                <div className='dz-filename'><span data-dz-name></span></div>
                <img data-dz-thumbnail />
            </div>
            <div className='dz-progress'><span className='dz-upload' data-dz-uploadprogress></span></div>
            <div className='dz-success-mark'><span><Icon name='check'></span></div>
            <div className='dz-error-mark'><span><Icon name='times'></span></div>
            <div className='dz-error-message'><span data-dz-errormessage></span></div>
        </div>

    postUrl : ->
        dest_dir = misc.encode_path(@props.current_path)
        postUrl  = window.smc_base_url + "/upload?project_id=#{@props.project_id}&dest_dir=#{dest_dir}"
        return postUrl

    render_close_button: ->
        <div className='close-button pull-right'>
            <span
                onClick   = {@props.close_button_onclick}
                className = 'close-button-x'
                style     = {cursor: 'pointer', fontSize: '18px', color:'gray'}>
                <i className="fa fa-times"></i>
            </span>
        </div>

    render: ->
        <div>
            {@render_close_button() if @props.close_button_onclick?}
            {render_header()}
            <div style={DROPSTYLE}>
                <DropComponent
                    config        = {postUrl: @postUrl()}
                    eventHandlers = {@props.dropzone_handler}
                    djsConfig     = {previewTemplate: ReactDOMServer.renderToStaticMarkup(@dropzone_template())} />
            </div>
        </div>

exports.SMC_Dropwrapper = rclass
    displayName: 'dropzone-wrapper'

    propTypes:
        project_id     : rtypes.string.isRequired    # The project to upload files to
        dest_path      : rtypes.string.isRequired    # The path for files to be sent
        config         : rtypes.object               # All supported dropzone.js config options
        event_handlers : rtypes.object
        show_upload    : rtypes.bool
        on_close       : rtypes.func
        disabled       : rtypes.bool

    getDefaultProps: ->
        config         : {}
        hide_previewer : false
        disabled       : false

    getInitialState: ->
        files : []

    get_djs_config: ->
        with_defaults = misc.defaults @props.config,
            url : @postUrl()
            previewsContainer : ReactDOM.findDOMNode(@refs.preview_container) ? ""
            previewTemplate   : ReactDOMServer.renderToStaticMarkup(@preview_template())
        , true
        return misc.merge(with_defaults, @props.config)

    postUrl: ->
        dest_dir = misc.encode_path(@props.dest_path)
        postUrl  = window.smc_base_url + "/upload?project_id=#{@props.project_id}&dest_dir=#{dest_dir}"
        return postUrl

    componentDidMount: ->
        if not @props.disabled
            @_create_dropzone()
            @_set_up_events()

    componentWillUnmount: ->
        if not @dropzone?
            return

        files = @dropzone.getActiveFiles()

        if files.length > 0
            # Stuff is still uploading...
            @queueDestroy = true

            destroyInterval = window.setInterval =>
                if @queueDestroy == false
                    # If the component remounts somehow, don't destroy the dropzone.
                    return window.clearInterval(destroyInterval)

                if @dropzone.getActiveFiles().length == 0
                    @_destroy()
                    return window.clearInterval(destroyInterval)
            , 500
        else
            @_destroy()

    componentDidUpdate: ->
        if not @props.disabled
            @queueDestroy = false
            @_create_dropzone()

    # Update Dropzone options each time the component updates.
    componentWillUpdate: (new_props) ->
        if new_props.disabled
            @_destroy()
        else
            @_create_dropzone()
            @dropzone.options = $.extend(true, {}, @dropzone.options, @get_djs_config())

    preview_template: ->
        <div className='dz-preview dz-file-preview'>
            <div className='dz-details'>
                <div className='dz-filename'><span data-dz-name></span></div>
                <img data-dz-thumbnail />
            </div>
            <div className='dz-progress'><span className='dz-upload' data-dz-uploadprogress></span></div>
            <div className='dz-success-mark'><span><Icon name='check'></span></div>
            <div className='dz-error-mark'><span><Icon name='times'></span></div>
            <div className='dz-error-message'><span data-dz-errormessage></span></div>
        </div>

    close_preview: ->
        @props.on_close?()
        @dropzone?.removeAllFiles()
        @setState(files : [])

    render_preview: ->
        if not @props.show_upload and @state.files.length == 0
            style = display : 'none'
        box_style =
            border       : '2px solid #ccc'
            boxShadow    : '4px 4px 2px #bbb'
            borderRadius : '5px'
            padding      : 0
            margin       : '10px'
            minHeight    : '40px'

        <div style={style}>
            <div className='close-button pull-right'>
                <span
                    onClick   = {@close_preview}
                    className = 'close-button-x'
                    style     = {cursor: 'pointer', fontSize: '18px', color:'gray'}
                >
                    <i className="fa fa-times"></i>
                </span>
            </div>
            {render_header()}
            <div ref      = 'preview_container'
                className = 'filepicker dropzone'
                style     = {box_style}
            />
        </div>

    render: ->
        <div>
            {@render_preview() if not @props.disabled}
            {@props.children}
        </div>

    _create_dropzone: ->
        if not @dropzone? and not @props.disabled
            dropzone_node = ReactDOM.findDOMNode(@)
            @dropzone = new Dropzone(dropzone_node, @get_djs_config())

    _set_up_events: ->
        return unless @dropzone?

        for name, handlers of @props.event_handlers
            # Check if there's an array of event handlers
            if misc.is_array(handlers)
                for handler in handlers
                    # Check if it's an init handler
                    if handler == 'init'
                        handler(@dropzone)
                    else
                        @dropzone.on(name, handler)
            else
                if name == 'init'
                    handlers(@dropzone)
                else
                    @dropzone.on(name, handlers)

        @dropzone.on 'addedfile', (file) =>
            if file
                files = @state.files
                files.push(file)
                @setState(files : files)

    # Removes ALL listeners and Destroys dropzone.
    # see https://github.com/enyo/dropzone/issues/1175
    _destroy: ->
        if not @dropzone?
            return
        @dropzone.off()
        @dropzone.destroy()
        delete @dropzone