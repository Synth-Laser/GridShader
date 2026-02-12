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
                half4 vertex : POSITION;
                half2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct vert2frag
            {
                half2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                half4 vertex : SV_POSITION;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            half4 _MainTex_ST;

            half4  _GridColour1,    _BackgroundColour1,  _GridSize1,  _Dotting1;
            half   _FilledLine1,    _GridLineThickness1, _SharpLine1;
            
            half4  _GridColour2,    _BackgroundColour2,  _GridSize2,  _Dotting2;
            half   _FilledLine2,    _GridLineThickness2, _SharpLine2;
            
            half4  _GridColour3,    _BackgroundColour3,  _GridSize3,  _Dotting3;
            half   _FilledLine3,    _GridLineThickness3, _SharpLine3;
            
            half4  _GridColour4,    _BackgroundColour4,  _GridSize4,  _Dotting4;
            half   _FilledLine4,    _GridLineThickness4, _SharpLine4;

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

            half GridTest
            (
                half2 uvNormalizedCoords,
                half4 gridSize, half4 dotting,
                half lineThickness, half isSharpLine
            )
            {
                half result = 0.0;
                half gridSizeX = 1 / gridSize.y;
                half gridSizeY = 1 / gridSize.x;

                half offsetX = gridSize.z;
                half offsetY = gridSize.w;

                half2 dotSpacing;
                dotSpacing.x = 1 / dotting.x;
                dotSpacing.y = 1 / dotting.y;

                half2 dotSize;
                dotSize.x = dotting.z / 100;
                dotSize.y = dotting.w / 100;

                half gridLineThickness = lineThickness / 1000000;

                half scaledX = (uvNormalizedCoords.x - offsetX) * gridSize.y;
                half cellLocalX = frac(scaledX + 0.5) - 0.5;
                half distToLineX = abs(cellLocalX) * gridSizeX;

                half sharpLineX = step(distToLineX, gridLineThickness);
                half smoothLineX = smoothstep(gridLineThickness, 0.0, distToLineX);
                half combineX = lerp(smoothLineX, sharpLineX, isSharpLine);
                combineX *= step(frac(uvNormalizedCoords.y / dotSpacing.y), dotSize.y);

                result += combineX;


                half scaledY = (uvNormalizedCoords.y - offsetY) * gridSize.x;
                half cellLocalY = frac(scaledY + 0.5) - 0.5;
                half distToLineY = abs(cellLocalY) * gridSizeY;

                half sharpLineY = step(distToLineY, gridLineThickness);
                half smoothLineY = smoothstep(gridLineThickness, 0.0, distToLineY);
                half combineY = lerp(smoothLineY, sharpLineY, isSharpLine);
                combineY *= step(frac(uvNormalizedCoords.x / dotSpacing.x), dotSize.x);

                result += combineY;

                result = min(result, 1);
                return result;
            }

            half4 GetLayer
            (
                half4 textureColor,
                half filledLine,
                half4 gridColour,
                half4 backgroundColour,
                
                half2 uvNormalizedCoords,
                half4 gridSize, half4 dotting,
                half lineThickness, half sharpLine
            )
            {
                //fill base
                half4 fillColour = lerp(half4(1, 1, 1, 1), half4(0, 0, 0, 1), filledLine);

                //bottom layer
                fillColour = lerp(fillColour, textureColor, textureColor.a);
                
                //grid mask
                half gridAmount = GridTest(uvNormalizedCoords, gridSize, dotting, lineThickness, sharpLine);
                
                half4 gridMask = (gridColour * gridAmount);
                gridMask += fillColour;
                gridMask.a = lerp(0, gridColour.a, gridAmount);


                half4 bgColor = backgroundColour;
                bgColor.a = backgroundColour.a;


                half4 combinedColour = lerp(bgColor, gridMask, gridMask.a);

                return combinedColour;
            }

            half4 frag(vert2frag input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                //texture sample
                half4 textureColor = tex2D(_MainTex, input.uv);

                half4 layer1 = GetLayer
                (
                    textureColor,
                    _FilledLine1, _GridColour1, _BackgroundColour1,
                    input.uv, _GridSize1, _Dotting1, _GridLineThickness1, _SharpLine1
                );
                half4 layer2 = GetLayer
                (
                    textureColor,
                    _FilledLine2, _GridColour2, _BackgroundColour2,
                    input.uv, _GridSize2, _Dotting2, _GridLineThickness2, _SharpLine2
                );
                half4 layer3 = GetLayer
                (
                    textureColor,
                    _FilledLine3, _GridColour3, _BackgroundColour3,
                    input.uv, _GridSize3, _Dotting3, _GridLineThickness3, _SharpLine3
                );
                half4 layer4 = GetLayer
                (
                    textureColor,
                    _FilledLine4, _GridColour4, _BackgroundColour4,
                    input.uv, _GridSize4, _Dotting4, _GridLineThickness4, _SharpLine4
                );

                half4 finalColour = layer1;
                finalColour = lerp(finalColour, layer2, layer2.a);
                finalColour = lerp(finalColour, layer3, layer3.a);
                finalColour = lerp(finalColour, layer4, layer4.a);

                return float4(finalColour);
            }
            ENDCG
        }
    }
}
