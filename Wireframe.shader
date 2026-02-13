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

            half4  _GridColour1,    _BackgroundColour1,  _GridSize1;
            half   _FilledLine1,    _GridLineThickness1;

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
                half4 gridSize,
                half lineThickness
            )
            {
                half result = 0.0;
                half gridSizeX = 1 / gridSize.y;
                half gridSizeY = 1 / gridSize.x;

                half offsetX = gridSize.z;
                half offsetY = gridSize.w;

                half gridLineThickness = lineThickness / 1000000;

                half scaledX = (uvNormalizedCoords.x - offsetX) * gridSize.y;
                half cellLocalX = frac(scaledX + 0.5) - 0.5;
                half distToLineX = abs(cellLocalX) * gridSizeX;

                half sharpLineX = step(distToLineX, gridLineThickness);

                result += sharpLineX;


                half scaledY = (uvNormalizedCoords.y - offsetY) * gridSize.x;
                half cellLocalY = frac(scaledY + 0.5) - 0.5;
                half distToLineY = abs(cellLocalY) * gridSizeY;

                half sharpLineY = step(distToLineY, gridLineThickness);

                result += sharpLineY;

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
                half4 gridSize,
                half lineThickness
            )
            {
                //fill base
                half4 fillColour = lerp(half4(1, 1, 1, 1), half4(0, 0, 0, 1), filledLine);

                //bottom layer
                fillColour = lerp(fillColour, textureColor, textureColor.a);
                
                //grid mask
                half gridAmount = GridTest(uvNormalizedCoords, gridSize, lineThickness);
                
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
                    input.uv, _GridSize1, _GridLineThickness1
                );

                return float4(layer1);
            }
            ENDCG
        }
    }
}
