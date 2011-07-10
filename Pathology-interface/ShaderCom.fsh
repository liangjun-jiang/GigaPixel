//
//  ShaderCom.fsh
//  test2.0
//
//  Created by Axel Hansen on 11/16/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

precision mediump float;
varying lowp vec4 colorVarying;
uniform sampler2D s_texture;
uniform sampler2D s_texture2;

uniform vec4 iKLT0; //iKLT[0-3]
uniform vec4 iKLT4; //iKLT[4-7]
uniform float iklt8; //iKLT[8]


varying vec2 v_texCoord;
//varying int channel;

uniform int channel;

//out vec4 result;
//uniform sampler2D sTex;
//uniform int inputLod;

//upscale function from Won-Ki
vec4 upscale(sampler2D sTex) {
 ivec2 p0 = ivec2(gl_FragCoord.xy);
 ivec2 q  = ivec2(p0.x&1,p0.y&1);
 ivec2 p1 = (p0 + 2*q*ivec2(1)-ivec2(1))/2;
 p0/=2;
 p1=clamp(p1,ivec2(0),ivec2(512)-ivec2(1));
 vec4 S0 = texelFetch(sTex,ivec2(p0.x,p0.y));//,inputLod);
 vec4 S1 = texelFetch(sTex,ivec2(p0.x,p1.y));//,inputLod);
 vec4 S2 = texelFetch(sTex,ivec2(p1.x,p0.y));//,inputLod);
 vec4 S3 = texelFetch(sTex,ivec2(p1.x,p1.y));//,inputLod);
 vec4 result = (9.0f*S0 + 3.0f*(S1+S2) + S3)/16.0f;
 return result;
}


void main()
{
	//gl_FragColor = texture2D( s_texture, v_texCoord );
	vec4 chans = texture2D( s_texture, v_texCoord );

	//vec4 chans = texture2D( 0, v_texCoord );
	if(channel>=0)
	{
		//vec4 kTex = chans;
		//vec4 lTek = texture2D( s_texture2, v_texCoord );
		
		float k = upscale(s_texture).r;  //CHANGE THIS FOR SLICES
		float l = upscale(s_texture2).r;
		
		float r;
		float g;
		float b;
		r = iKLT0.r*k + iKLT0.g + iKLT0.b*255.0f;
		g = iKLT0.a + iKLT1.r*l + iKLT1.g*255.0f;
		b = iKLT1.b*k + iKLT1.a*l + iKLT8*255.0f;
		
		gl_FragColor = vec4(r, g, b, 255);
	}
	else if(channel==-1)
	{
		gl_FragColor = vec4(0, 255, 0, 255);
	}
	else if(channel==-2)
	{
		gl_FragColor = vec4(128, 255, 0, 255);
	}
	else if(channel==-3)
	{
		gl_FragColor = vec4(chans.r, chans.g, chans.b, chans.a);
	}



}
