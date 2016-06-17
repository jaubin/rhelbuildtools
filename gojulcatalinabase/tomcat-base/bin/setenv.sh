# Put your Tomcat customizations there
JAVA_OPTS="$JAVA_OPTS -Xmx2048m"
# Configures logback so that it uses JNDI configuration, if you use logback
JAVA_OPTS="$JAVA_OPTS -Dlogback.ContextSelector=JNDI"
# Configures jboss logger to use slf4j (useful for Hibernate)
JAVA_OPTS="$JAVA_OPTS -Dorg.jboss.logging.provider=slf4j"


