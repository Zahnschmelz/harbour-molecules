import QtQuick 2.6

/*
 * Molecule.qml - ein einzelnes Molekül
 *
 * Portiert scenes/Molecule.tscn + shaders/molecule.gdshader (Godot 4.0)
 * nach Qt Quick: Ein Quad mit Fragment-Shader (Fresnel-Glow + animierte
 * Noise-Blitze). Die Noise-Textur wird über init() geteilt gesetzt.
 *
 * Der Fragment-Shader wurde 1:1 übernommen:
 *   - UV -> qt_UV (beide 0..1 über das Quad)
 *   - TIME -> time (wird vom Spiel-Takt weitergeführt, läuft auch pausiert)
 *   - texture() -> texture2D(), Farbterm unverändert
 *   - "Carve"-Optik: außerhalb von r > 1 komplett transparent
 */

Item {
    id: root

    property real radius: 30
    property color molColor: "#00ff00"
    property real time: 0

    width: radius * 2
    height: radius * 2

    function init(noiseSource, shaderOffset) {
        effect.noiseTex = noiseSource
        effect.offset = shaderOffset
    }

    ShaderEffect {
        id: effect
        anchors.fill: parent

        property variant noiseTex: null
        property color color: root.molColor
        property real offset: 0.1
        property real time: root.time

        vertexShader: "
            uniform highp mat4 qt_Matrix;
            attribute highp vec4 qt_Vertex;
            attribute highp vec2 qt_MultiTexCoord0;
            varying highp vec2 qt_UV;
            void main() {
                qt_UV = qt_MultiTexCoord0;
                gl_Position = qt_Matrix * qt_Vertex;
            }
        "

        fragmentShader: "
            precision mediump float;

            varying highp vec2 qt_UV;
            uniform lowp sampler2D noiseTex;
            uniform mediump vec4 color;
            uniform mediump float offset;
            uniform mediump float time;

            const mediump float lightningSmoothness = 0.30;
            const mediump float speed = 0.02;

            void main() {
                mediump float x = qt_UV.x * 2.0 - 1.0;
                mediump float y = qt_UV.y * 2.0 - 1.0;
                mediump float r = sqrt(x * x + y * y);

                if (r > 1.0) {
                    // Draußen komplett transparent (wie im Original)
                    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
                } else {
                    mediump float z = sqrt(1.0 - r * r);
                    // \"Falscher\" Normalenvektor aus der Quad-Position;
                    // view ist immer +Z => dot(normal, view) = z.
                    // (normal und view sind Einheitsvektoren,
                    //  daher entfaellt normalize(); (1-z)^4 als Produkt.)
                    mediump float fres = 1.0 - clamp(z, 0.0, 1.0);
                    fres = fres * fres * fres * fres;

                    mediump vec2 baseUv1 = qt_UV * 0.5 + vec2(time * speed, offset);
                    mediump vec2 baseUv2 = qt_UV * 0.5 + vec2(0.1 + offset, time * speed);
                    mediump float n1 = texture2D(noiseTex, baseUv1).r;
                    mediump float n2 = texture2D(noiseTex, baseUv2).r;
                    mediump float center = smoothstep(-lightningSmoothness, lightningSmoothness, n1 - n2);
                    mediump float lightning = clamp((0.5 - abs(center - 0.5)) * 1.5, 0.0, 1.0);

                    mediump float basicFresnel = clamp(fres * 2.0 + lightning * 0.7, 0.0, 1.0);
                    // Godot blendt straight-alpha (rgb*f mit a=f), Qt Quick
                    // erwartet premultiplied Ausgabe => rgb zusaetzlich
                    // mit f multiplizieren, Ergebnis ist identisch.
                    mediump float a = basicFresnel;
                    gl_FragColor = vec4(color.rgb * (basicFresnel * 1.4 * a), a);
                }
            }
        "
    }
}
