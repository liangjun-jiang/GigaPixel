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
uniform float iKLT8; //iKLT[8]


varying vec2 v_texCoord;
//varying int channel;

uniform int channel;

//out vec4 result;
//uniform sampler2D sTex;
//uniform int inputLod;

//upscale function from Won-Ki
vec4 upscale(sampler2D sTex) {
 ivec2 p0=ivec2(gl_FragCoord.xy);
 int p0X;
 int p0Y;
 p0X=1;
 p0Y=1;
 if(ceil(float(p0.x)/2.0)==float(p0.x)/2.0)
 {
	p0X=0;
 }
 if(ceil(float(p0.y)/2.0)==float(p0.y)/2.0)
 {
	p0Y=0;
 }
 ivec2 q=ivec2(p0X, p0Y);
 ivec2 p1 = (p0 + 2*q*ivec2(1)-ivec2(1))/2;
 p0/=2;
 p1=ivec2(clamp(vec2(p1),vec2(0),vec2(512)-vec2(1)));
/* vec4 S0 = texelFetch(sTex,ivec2(p0.x,p0.y));//,inputLod);
 vec4 S1 = texelFetch(sTex,ivec2(p0.x,p1.y));//,inputLod);
 vec4 S2 = texelFetch(sTex,ivec2(p1.x,p0.y));//,inputLod);
 vec4 S3 = texelFetch(sTex,ivec2(p1.x,p1.y));//,inputLod);*/
 vec4 S0 = texture2D(sTex,vec2(p0.x,p0.y));//,inputLod);
 vec4 S1 = texture2D(sTex,vec2(p0.x,p1.y));//,inputLod);
 vec4 S2 = texture2D(sTex,vec2(p1.x,p0.y));//,inputLod);
 vec4 S3 = texture2D(sTex,vec2(p1.x,p1.y));//,inputLod);

 vec4 result = (9.0*S0 + 3.0*(S1+S2) + S3)/16.0;
 return result;
// return vec4(0,0,0,0);
}


void main()
{
	//gl_FragColor = texture2D( s_texture, v_texCoord );

	//vec4 chans = texture2D( 0, v_texCoord );
	if(channel>=0)
	{
		//vec4 kTex = chans;
		//vec4 lTek = texture2D( s_texture2, v_texCoord );
		
		//get slice from each
		//float k = upscale(s_texture).r;  //slice 0
		vec4 kFull = texture2D( s_texture, v_texCoord);//slice 0
		float k;
		float l;

		//float l = upscale(s_texture2).r;
		vec4 lFull = texture2D( s_texture2, vec2(v_texCoord.x, v_texCoord.y));//slice 0
		if(channel==0)
		{
		k=kFull.r;
		l=lFull.r;
		}
		else if(channel==1)
		{
		k=kFull.g;
		l=lFull.g;
		}
		else if(channel==2)
		{
		k=kFull.b;
		l=lFull.b;
		}
		
		//convert w/ iKLT
		float r=0.0;
		float g=0.0;
		float b=0.0;
		r = iKLT0[0]*k + iKLT0[1]*l + iKLT0[2];//*255.0;
		g = iKLT0[3]*k + iKLT4[0]*l + iKLT4[1];//*255.0;
		b = iKLT4[2]*k + iKLT4[3]*l + iKLT8;//*255.0;
		r=clamp(r, 0.0, 1.0);//255.0);
		g=clamp(g, 0.0, 1.0);//255.0);
		b=clamp(b, 0.0, 1.0);//255.0);
		
		gl_FragColor = vec4(b, g, r, 255);
		//gl_FragColor = vec4(0, 255, 0, 255);
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
		vec4 chans = texture2D( s_texture, v_texCoord );
		gl_FragColor = vec4(chans.r, chans.g, chans.b, chans.a);
	}
	else if(channel==-4)
	{
		gl_FragColor = vec4(0, 128, 255, 255);
	}
	//	vec4 chans = texture2D( s_texture2, v_texCoord );
	//	gl_FragColor = vec4(chans.r, chans.g, chans.b, chans.a);
}



/*
//
//  Shader.fsh
//  test2.0
//
//  Created by Axel Hansen on 11/16/10.
//  Copyright 2010 Harvard University. All rights reserved.
//

precision mediump float;
varying lowp vec4 colorVarying;
uniform sampler2D s_texture;
varying vec2 v_texCoord;
//varying int channel;

uniform int channel;

void main()
{
	//gl_FragColor = texture2D( s_texture, v_texCoord );
	vec4 chans = texture2D( s_texture, v_texCoord );
	//vec4 chans = texture2D( 0, v_texCoord );
	//vec4 chans = texture2D( 0, v_texCoord );
	if(channel==0)
	{
		gl_FragColor = vec4(chans.r, chans.r, chans.r, 255);
	}
	else if(channel==1)
	{
		gl_FragColor = vec4(chans.g, chans.g, chans.g, 255);
	}
	else if(channel==2)
	{
		gl_FragColor = vec4(chans.b, chans.b, chans.b, 255);
	}
	else if(channel==3)
	{
		gl_FragColor = vec4(chans.a, chans.a, chans.a, 255);
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
*/