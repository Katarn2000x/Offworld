﻿/**************************************************************************

Filename    :   UILoader.as

Copyright   :   Copyright 2012 Autodesk, Inc. All Rights reserved.

Use of this software is subject to the terms of the Autodesk license
agreement provided at the time of installation or download, or which
otherwise accompanies this software in either electronic or hard copy form.

**************************************************************************/

package scaleform.clik.controls 
{
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.events.Event;
    import flash.events.ProgressEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    
    import scaleform.clik.constants.InvalidationType;
    import scaleform.clik.core.UIComponent;
    import scaleform.clik.events.ComponentEvent;
    
    /**
     * The CLIK UILoader loads an external SWF/GFX or image using only the path. UILoaders also support auto-sizing of the loaded asset to fit in its bounding box. Asset loading is asynchronous if both GFx and the platform running it has threading support.
     *
     * <p><b>Inspectable Properties</b></p>
     * <p>
     * A MovieClip that derives from the UILoader component will have the following inspectable properties:
     * <ul>
     *  <li><i>autoSize</i>: If set to true, sizes the loaded to content to fit in the UILoader’s bounds.</li>
     *  <li><i>enableInitCallback</i>:  If set to true, Extensions.CLIK_addedToStageCallback() will be fired when a component is loaded. This method receives the instance name, target path, and a reference the component as parameters. Extensions.CLIK_addedToStageCallback() should be overriden from the game engine using GFx FunctionObjects.</li>
     *  <li><i>maintainAspectRatio</i>: If true, the loaded content will be fit based on its aspect ratio inside the UILoader’s bounds. If false, then the content will be stretched to fit the UILoader bounds.</li>
     *  <li><i>source</i>: The SWF/GFX or image filename to load.</li>
     *  <li><i>visible</i>: Hides the component if set to false.</li>
     * </ul>
     * </p>
     * 
     * <p><b>States</b></p>
     * <p>
     * There are no states for the UILoader component. If a SWF/GFX is loaded into the UILoader, then it may have its own states.
     * </p>
     * 
     * <p><b>Events</b></p>
     * <p>
     * All event callbacks receive a single Object parameter that contains relevant information about the event. The following properties are common to all events.
     * <ul>
     *      <li><i>type</i>: The event type.</li>
     *      <li><i>target</i>: The target that generated the event.</li>
     * </ul>
     *
     * The events generated by the UILoader component are listed below. The properties listed next to the event are provided in addition to the common properties.
     * <ul>
     *      <li><b>ComponentEvent.SHOW</b>: The component’s visible property has been set to true at runtime.</li>
     *      <li><i>ComponentEvent.HIDE</i>: The component’s visible property has been set to false at runtime.</li>
     *      <li><i>ProgressEvent.PROGRESS</i>: Content is in the process of being loaded regardless whether the content can or cannot be loaded. This event will be fired continuously until the content is loaded.</li>
     *      <li><i>Event.OPEN</i>: Content loading has started.</li> 
     *      <li><i>Event.INIT</i>: The content being loaded is now accessible via the .content property.</li> 
     *      <li><i>Event.COMPLETE</i>: Content loading has been completed.</li> 
     *      <li><i>IOErrorEvent.IO_ERROR</i>: Content specified in the source property could not be loaded.</li>
     * </ul>
     * </p>
     */
    [InspectableList("visible", "autoSize", "source", "maintainAspectRatio", "enableInitCallback")]
    public class UILoader extends UIComponent 
    {
    // Constants:
        
    // Public Properties:
        public var bytesLoaded:int = 0;
        public var bytesTotal:int = 0;
    
    // Protected Properties:
        /** @private */
        protected var _source:String;
        /** @private */
        protected var _autoSize:Boolean = true;
        /** @private */
        protected var _maintainAspectRatio:Boolean = true;
        /** @private */
        protected var _loadOK:Boolean = false;
        /** @private */
        protected var _sizeRetries:Number = 0;
        /** @private */
        protected var _visiblilityBeforeLoad:Boolean = true;
        /** @private */
        protected var _isLoading:Boolean = false;
        
    // UI Elements:
        /** @private */
        public var bg:DisplayObject;
        public var loader:Loader;
        
    // Initialization:
        public function UILoader() {
            super();
        }
        
    // Public Getter / Setters:
        /** Automatically scale the content to fit the container. */
        [Inspectable(defaultValue="true")]
        public function get autoSize():Boolean { return _autoSize; }
        public function set autoSize(value:Boolean):void {
            _autoSize = value;
            invalidateSize();
        }
        
        /** Set the source of the content to be loaded. */
        [Inspectable(defaultValue="")]
        public function get source():String { return _source; }
        public function set source(value:String):void { 
            if (_source == value) { return; }
            if ((value == "" || value == null) && loader.content == null) { 
                unload();
            }
            else {
                load(value);
            }
        }
        
        /**
         * Maintain the original content's aspect ration when scaling it. If autoSize is false, this property is ignored.
         */
        [Inspectable(defaultValue="true")]
        public function get maintainAspectRatio():Boolean { return _maintainAspectRatio; }
        public function set maintainAspectRatio(value:Boolean):void {
            _maintainAspectRatio = value;
            invalidateSize();
        }
        
        /** 
         * A read-only property that returns the loaded content of the UILoader.
         */
        public function get content():DisplayObject { 
            return loader.content;
        }
        
        /**
         * A read-only property that returns the percentage that the content is loaded. The percentage is normalized to a 0-100 range.
         */
        public function get percentLoaded():Number {
            if (bytesTotal == 0 || _source == null) { return 0; }
            return bytesLoaded / bytesTotal * 100;
        }
        
        /**
         * Show or hide the component. Allows the visible property to be overridden, and 
         * dispatch a "show" or "hide" event.
         */
        [Inspectable(defaultValue="true")]
        override public function get visible():Boolean { return super.visible; }
        override public function set visible(value:Boolean):void {
            if (_isLoading) { 
                _visiblilityBeforeLoad = value;
            }
            else {
                super.visible = value;
            }
        }
        
    // Public Methods:
        /** Unload the currently loaded content, or stop any pending or active load. */
        public function unload():void {
            if (loader != null) { 
                visible = _visiblilityBeforeLoad;
                loader.unloadAndStop(true);
            }
            _source = null;
            _loadOK = false;
            _sizeRetries = 0;
        }
        
        /** @private */
        override public function toString():String { 
            return "[CLIK UILoader " + name + "]";
        }
        
    // Protected Methods:
        /** @private */
        override protected function configUI():void {
            super.configUI();
            initSize();
            if (bg != null) {
                removeChild(bg);
                bg = null;
            }
            if (loader == null && _source) { 
                load(_source); 
            }
        }
        
        /** @private */
        protected function load(url:String):void {
            if (url == "") { return; }
            unload();
            _source = url;
            _visiblilityBeforeLoad = visible;
            visible = false;
            if (loader == null) {
                loader = new Loader();
                loader.contentLoaderInfo.addEventListener( Event.OPEN, handleLoadOpen, false, 0, true );
                loader.contentLoaderInfo.addEventListener( Event.INIT, handleLoadInit, false, 0, true );
                loader.contentLoaderInfo.addEventListener( Event.COMPLETE, handleLoadComplete, false, 0, true );
                loader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, handleLoadProgress, false, 0, true );
                loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, handleLoadIOError, false, 0, true );
            }
            addChild( loader );
            _isLoading = true;
            loader.load( new URLRequest(_source) );
        }
        
        /** @private */
        override protected function draw():void {
            if (!_loadOK) { return; }
            if (isInvalid(InvalidationType.SIZE)) {
                loader.scaleX = loader.scaleY = 1;
                if (!_autoSize) { 
                    visible = _visiblilityBeforeLoad;
                } 
                else {
                    if (loader.width <= 0) { 
                        if (_sizeRetries < 10) { 
                            _sizeRetries++;
                            invalidateData(); 
                        }
                        else { 
                            trace("Error: " + this + " cannot be autoSized because content width is <= 0!"); 
                        }
                        return; 
                    }
                    if (_maintainAspectRatio) { 
                        loader.scaleX = loader.scaleY = Math.min( height/loader.height, width/loader.width );
                        loader.x = (_width - loader.width >> 1);
                        loader.y = (_height - loader.height >> 1);
                    } else {
                        loader.width = _width;
                        loader.height = _height;
                    }
                    visible = _visiblilityBeforeLoad;
                }
            }
        }
        
        /** @private */
        protected function handleLoadIOError( ioe:Event ):void {
            visible = _visiblilityBeforeLoad;
            dispatchEvent( ioe );
        }
        
        /** @private */
        protected function handleLoadOpen( e:Event ):void {
            dispatchEvent( e );
        }
        
        /** @private */
        protected function handleLoadInit( e:Event ):void {
            dispatchEvent( e );
        }
        
        /** @private */
        protected function handleLoadProgress( pe:ProgressEvent ):void {
            bytesLoaded = pe.bytesLoaded;
            bytesTotal = pe.bytesTotal;
            dispatchEvent( pe );
        }
        
        /** @private */
        protected function handleLoadComplete( e:Event ):void {
            _loadOK = true;
            _isLoading = false;
            invalidateSize();
            validateNow();
            dispatchEvent( e );
        }
        
    }
}
