//
//  Shader.vsh
//  test2.0
//
//  Created by Axel Hansen on 11/16/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

//#version 140


//attribute vec2 channel;
attribute vec4 position;
attribute vec4 color;
attribute vec2 textureCo;

varying vec4 colorVarying;
varying vec2 v_texCoord;
//varying int c;

uniform float translate;
uniform mat4 matrix;



void main()
{
    //gl_Position = position;
	gl_Position = matrix * position;
    //gl_Position.y += sin(translate) / 2.0;
	v_texCoord=textureCo;
    colorVarying = color;
	//c=channel[0];
}
