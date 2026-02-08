Shader "Unlit/Grid"
{
    Properties
    {
        [Header(Colors)]
        [Space()]

        _MainTex
            ("Texture", 2D)
            = "clear" {}

        [Header(Layer 1 Grid)]
        [Space()]

        [HDR]       _GridColour1         ("Grid Colour", Color)                      = (.255, .0, .0, 1)
        [Toggle()]  _FilledLine1         ("Fill line with color", float)             = 0
        [HDR]       _BackgroundColour1   ("Background Colour", Color)                = (.255, .0, .0, 1)
                    _GridSize1           ("Grid size params", Vector)                = (2, 1, 0, 0)
                    _GridLineThickness1  ("Grid Line Thickness", Range(1, 100000))   = 3000
        [Toggle()]  _SharpLine1          ("Use sharp lines", float)                  = 0
                    _Dotting1            ("Dot Count, fill", Vector)                 = (5, 5, 50, 50)

        [Header(Layer 2 Waypoints)]
        [Space()]

        [HDR]       _GridColour2         ("Grid Colour", Color)                      = (.255, .0, .0, 1)
        [Toggle()]  _FilledLine2         ("Fill line with color", float)             = 0
        [HDR]       _BackgroundColour2   ("Background Colour", Color)                = (.255, .0, .0, 1)
                    _GridSize2           ("Grid size params", Vector)                = (2, 1, 0, 0)
                    _GridLineThickness2  ("Grid Line Thickness", Range(1, 100000))   = 3000
        [Toggle()]  _SharpLine2          ("Use sharp lines", float)                  = 0
                    _Dotting2            ("Dot Count, fill", Vector)                 = (5, 5, 50, 50)

        [Header(Layer 3 Bars)]
        [Space()]

        [HDR]       _GridColour3         ("Grid Colour", Color)                      = (.255, .0, .0, 1)
        [Toggle()]  _FilledLine3         ("Fill line with color", float)             = 0
        [HDR]       _BackgroundColour3   ("Background Colour", Color)                = (.255, .0, .0, 1)
                    _GridSize3           ("Grid size params", Vector)                = (2, 1, 0, 0)
                    _GridLineThickness3  ("Grid Line Thickness", Range(1, 100000))   = 3000
        [Toggle()]  _SharpLine3          ("Use sharp lines", float)                  = 0
                    _Dotting3            ("Dot Count, fill", Vector)                 = (5, 5, 50, 50)

        [Header(Layer 4 Segments)]
        [Space()]

        [HDR]       _GridColour4         ("Grid Colour", Color)                      = (.255, .0, .0, 1)
        [Toggle()]  _FilledLine4         ("Fill line with color", float)             = 0
        [HDR]       _BackgroundColour4   ("Background Colour", Color)                = (.255, .0, .0, 1)
                    _GridSize4           ("Grid size params", Vector)                = (2, 1, 0, 0)
                    _GridLineThickness4  ("Grid Line Thickness", Range(1, 100000))   = 3000
        [Toggle()]  _SharpLine4          ("Use sharp lines", float)                  = 0
                    _Dotting4            ("Dot Count, fill", Vector)                 = (5, 5, 50, 50)
    }
    SubShader
    {
        Tags  {"Queue" = "Transparent" "RenderType" = "Transparent" } 
        LOD 100
        Zwrite off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct vert2frag
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4  _GridColour1,    _BackgroundColour1,  _GridSize1,  _Dotting1;
            float   _FilledLine1,    _GridLineThickness1, _SharpLine1;
            
            float4  _GridColour2,    _BackgroundColour2,  _GridSize2,  _Dotting2;
            float   _FilledLine2,    _GridLineThickness2, _SharpLine2;
            
            float4  _GridColour3,    _BackgroundColour3,  _GridSize3,  _Dotting3;
            float   _FilledLine3,    _GridLineThickness3, _SharpLine3;
            
            float4  _GridColour4,    _BackgroundColour4,  _GridSize4,  _Dotting4;
            float   _FilledLine4,    _GridLineThickness4, _SharpLine4;

            vert2frag vert (appdata vertInput)
            {
                vert2frag v2fOutput;

                UNITY_SETUP_INSTANCE_ID(vertInput);
                UNITY_TRANSFER_INSTANCE_ID(vertInput, v2fOutput);
                
                v2fOutput.vertex = UnityObjectToClipPos(vertInput.vertex);
                v2fOutput.uv = TRANSFORM_TEX(vertInput.uv, _MainTex);

                UNITY_TRANSFER_FOG(v2fOutput, v2fOutput.vertex);

                return v2fOutput;
            }

            float GridTest
            (
                float2 uvNormalizedCoords,
                float4 gridSize, float4 dotting,
                float lineThickness, float sharpLine
            )
            {
                float result = 0.0;
                float gridSizeX = 1 / gridSize.y;
                float gridSizeY = 1 / gridSize.x;

                float offsetX = gridSize.z;
                float offsetY = gridSize.w;

                float2 dotSpacing;
                dotSpacing.x = 1 / dotting.x;
                dotSpacing.y = 1 / dotting.y;

                float2 dotSize;
                dotSize.x = dotting.z / 100;
                dotSize.y = dotting.w / 100;

                float gridLineThickness = lineThickness / 1000000;

                //grid spacing X
                for (float cell = offsetX % gridSizeX; cell <= 1; cell += gridSizeX)
                {
                    if (frac(uvNormalizedCoords.y / dotSpacing.y) >= dotSize.y)
                        continue;

                    float currentCoordinate = uvNormalizedCoords.x - cell;

                    float isNotOnLine = 
                    sharpLine ?
                        step(gridLineThickness, abs(currentCoordinate))
                    :
                        smoothstep(0.0, gridLineThickness, abs(currentCoordinate))
                    ;

                    float isOnLine = 1.0 - isNotOnLine;

                    result += isOnLine;
                }
                //grid spacing Y
                for (float cell = offsetY % gridSizeY; cell <= 1; cell += gridSizeY)
                {
                    if (frac(uvNormalizedCoords.x / dotSpacing.x) >= dotSize.x)
                        continue;

                    float currentCoordinate = uvNormalizedCoords.y - cell;
                    
                    float isNotOnLine = 
                    sharpLine ?
                        step(gridLineThickness, abs(currentCoordinate))
                    :
                        smoothstep(0.0, gridLineThickness, abs(currentCoordinate))
                    ;

                    float isOnLine = 1.0 - isNotOnLine;

                    result += isOnLine;
                }

                if (result > 1) result = 1;
                return result;
            }

            fixed4 GetLayer
            (
                fixed4 textureColor,
                float filledLine,
                float4 gridColour,
                float4 backgroundColour,
                
                float2 uvNormalizedCoords,
                float4 gridSize, float4 dotting,
                float lineThickness, float sharpLine
            )
            {
                //fill base
                fixed4 fillColour = 
                filledLine ?
                    fixed4(0, 0, 0, 1)
                :
                    fixed4(1, 1, 1, 1)
                ;

                //bottom layer
                fillColour = lerp(fillColour, textureColor, textureColor.a);
                
                //grid mask
                float gridAmount = GridTest(uvNormalizedCoords, gridSize, dotting, lineThickness, sharpLine);
                
                fixed4 gridMask = (gridColour * gridAmount);
                gridMask += fillColour;
                gridMask.a = lerp(0, gridColour.a, gridAmount);


                fixed4 bgColor = backgroundColour;
                bgColor.a = backgroundColour.a;


                fixed4 combinedColour = lerp(bgColor, gridMask, gridMask.a);

                return combinedColour;
            }

            fixed4 frag(vert2frag input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                //texture sample
                fixed4 textureColor = tex2D(_MainTex, input.uv);

                fixed4 layer1 = GetLayer
                (
                    textureColor,
                    _FilledLine1, _GridColour1, _BackgroundColour1,
                    input.uv, _GridSize1, _Dotting1, _GridLineThickness1, _SharpLine1
                );
                fixed4 layer2 = GetLayer
                (
                    textureColor,
                    _FilledLine2, _GridColour2, _BackgroundColour2,
                    input.uv, _GridSize2, _Dotting2, _GridLineThickness2, _SharpLine2
                );
                fixed4 layer3 = GetLayer
                (
                    textureColor,
                    _FilledLine3, _GridColour3, _BackgroundColour3,
                    input.uv, _GridSize3, _Dotting3, _GridLineThickness3, _SharpLine3
                );
                fixed4 layer4 = GetLayer
                (
                    textureColor,
                    _FilledLine4, _GridColour4, _BackgroundColour4,
                    input.uv, _GridSize4, _Dotting4, _GridLineThickness4, _SharpLine4
                );

                fixed4 finalColour = layer1;
                finalColour = lerp(finalColour, layer2, layer2.a);
                finalColour = lerp(finalColour, layer3, layer3.a);
                finalColour = lerp(finalColour, layer4, layer4.a);

                return float4(finalColour);
            }
            ENDCG
        }
    }
}
