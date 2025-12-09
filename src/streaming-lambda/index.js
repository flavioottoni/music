const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const s3 = new S3Client({ region: "us-east-1" });
const BUCKET_NAME = process.env.MUSIC_BUCKET_NAME;

exports.handler = async (event) => {
    // Evento vindo do API Gateway
    const { trackId, userId } = JSON.parse(event.body);

    // 1. Validar Assinatura do Usuário (Consulta ao DynamoDB ou Redis)
    // const isSubscribed = await checkSubscription(userId);
    // if (!isSubscribed) return { statusCode: 403, body: "Subscription required" };

    const objectKey = `tracks/${trackId}.mp3`;

    try {
        const command = new GetObjectCommand({
            Bucket: BUCKET_NAME,
            Key: objectKey,
        });

        // Gera URL válida por 1 hora (3600 segundos)
        const url = await getSignedUrl(s3, command, { expiresIn: 3600 });

        // Log de Insight: Usuário iniciou streaming
        console.log(JSON.stringify({
            event: "STREAM_START",
            user: userId,
            track: trackId,
            timestamp: new Date().toISOString()
        }));

        return {
            statusCode: 200,
            body: JSON.stringify({ streamUrl: url }),
            headers: { "Content-Type": "application/json" }
        };
    } catch (error) {
        console.error("Error generating presigned URL", error);
        return { statusCode: 500, body: "Internal Server Error" };
    }
};