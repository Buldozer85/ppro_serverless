package example
import com.amazonaws.services.lambda.runtime.Context
import com.amazonaws.services.lambda.runtime.RequestHandler

class Handler : RequestHandler<Map<String, String>, Map<String, String>> {
    override fun handleRequest(input: Map<String, String>, context: Context): Map<String, String> {
        val name = input["name"] ?: "Unknown"
        return mapOf("message" to "Hello, $name!")
    }
}